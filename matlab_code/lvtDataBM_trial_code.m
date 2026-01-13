% lvt BioMotion protocol lib
function lvtDataBM_trial(dataFile, trialIds, fromApp, userOutputDir)
    arguments
        dataFile string
        trialIds(1,:) {mustBeNumeric}
        fromApp {mustBeNumericOrLogical} = 0
        userOutputDir = ""
    end

    clear outputNamePrefix;
    if (~fromApp)
        [testParams, trialCnt, trialsParams, trialsData, ...
            trialsEvents, ~, trialsFrames, trialsCounters] = loadlvtdata(dataFile);
    else
         [testParams, trialCnt, trialsParams, trialsData, trialsEvents, trialsFrames, trialsCounters] = ...
             evalin('base',  'deal(testParams, trialCnt, trialsParams, trialsData,trialsEvents, trialsFrames, trialsCounters)');

         if exist('demoBMEyeTraceAnalysis', 'class') == 8

            % outputDir = demoBMEyeTraceAnalysis().OutputDirEditField.Value;
            outputDir = userOutputDir;
            % turn string to char
            outputDir = char(outputDir);

            if exist(outputDir,"dir") == 7
                if (~outputDir(end) == '/' && ~outputDir(end) == '\')
                    outputDir = [outputDir, '/'];
                end

                [~, name] = fileparts(dataFile);
                % 生成文件夹和存放文件路径
%                 [~, name] = fileparts(dataFile);
%                 outputDir=strcat(outputDir, name, '\');
%                 if ~exist(outputDir, 'dir')
%                     mkdir(outputDir);
%                 end
%                 outputNamePrefix = strcat(outputDir, name); 
            end
         end
    end

    % -1 means to process all trials
    if (any(trialIds == -1))
        trialIds = 1:trialCnt;
        % 如果遍历所有trials，结果保存部分标识为1
        saveRsltIdx = 1; 
    end

    % 处理 testParams
    % 检查测试文件protocol是否正确
    if str2double(testParams.protocol) ~= 122
        error('Not protocol BioMotion!')
    end
    if (~isempty(find(any(trialIds > trialCnt) || any(trialIds <=0), 1)))
        error('TrialId should be in [1,%d]', trialCnt);
    end

    % 获取analog,counter的相关设置
    helper = lvtDataHelper();
    [numAnalog, posLeftX, posLeftY, posRightX, posRightY] = helper.processAnalogChannels(...
        str2double(testParams.analogChannelMask),...
        str2double(testParams.leftXChan), str2double(testParams.leftYChan),...
        str2double(testParams.rightXChan), str2double(testParams.rightYChan));
    numCounter = sum(bitget(str2double(testParams.counterChannelMask), 1:2));

    % 是否左眼为"primaryEye" 
    leftIsPrimaryEye = ~isfield(testParams, 'primaryEye') || testParams.primaryEye ~= "right";

    % 生成抽样绘图种子
    poolSize = 200;
    windowSize = 10;
    rngSeed = 42;
    seeds = eyeTraceSeeds(poolSize, windowSize, rngSeed);
    % fprintf('Sampled seeds:\n'); disp(seeds);

    %% 初始化分析参数
    global eye;

    % 此处专门生成文件夹
    [eyeTrcRsltPath]=BMA_mekDir(outputDir, fullfile('loadLvtRslt','plot','eyeTrace',name)); % 眼动轨迹图存放
    [nonChoiTrcRsltPath]=BMA_mekDir(outputDir, fullfile('loadLvtRslt','plot','nonChoieyeTrace',name)); % 眼动轨迹图存放
    [trlFixsRsltPath]=BMA_mekDir(outputDir, fullfile('loadLvtRslt','plot','trialFixs',name)); % 注视轨迹图存放
    [fixsRsltPath]=BMA_mekDir(outputDir, fullfile('loadLvtRslt','fixs')); % 注视结果
    [saccsRsltPath]=BMA_mekDir(outputDir, fullfile('loadLvtRslt','saccs')); % 眼跳结果
    [trlsRsltPath]=BMA_mekDir(outputDir, fullfile('loadLvtRslt','trls')); % trial结果

    % 获取屏幕参数
    vals = str2double(split(testParams.testViewSetting, ','));
    eye.AP.screen.width = vals(1);
    eye.AP.screen.height = vals(2);
    eye.AP.screen.distance = vals(length(vals));
    screen = eye.AP.screen;
   
    % 以屏幕边界作为图像显示边界
    eye.AP.screen.screen=[-(eye.AP.screen.width/2) eye.AP.screen.width/2 -(eye.AP.screen.height/2) eye.AP.screen.height/2];

    % convert deg to cm
    [cmPerDegH, cmPerDegV] = cmPerDegree(eye.AP);
    eye.AP.blink.limits = [eye.APdeg.blink.limits(1)*cmPerDegH, eye.APdeg.blink.limits(2)*cmPerDegH,...
        eye.APdeg.blink.limits(3)*cmPerDegV, eye.APdeg.blink.limits(4)*cmPerDegV];
    eye.AP.blink.vertThresh = eye.APdeg.blink.vertThresh * cmPerDegV;
    eye.AP.blink.window = eye.APdeg.blink.window;
    eye.AP.fix.params.disp.Disp = eye.APdeg.fix.params.disp.Disp * cmPerDegV;
    eye.AP.fix.params.disp.minDuration = eye.APdeg.fix.params.disp.minDuration;

 
    % 准备盯视和眼跳的结果txt文件
    if exist('outputDir',"var") == 1
        headerOK = 0;
        fid_fix = fopen(fullfile(fixsRsltPath, strcat(name, '-fixationReport.txt')), 'w');
        fid_saccade = fopen(fullfile(saccsRsltPath, strcat(name, '-saccadeReport.txt')), 'w');
    end
    
    % 新建两个变量保存所有的盯视和眼跳结果
    fixation_list=[];
    saccade_list=[];

    % 新建变量保存眼动结果
    nonBlinksTrialsData = {};
    interplaTrialsData = {};
    % nonChoicetrialsData = {};
    
    % 新建一个变量保存无效试次
    nonUse_tid=[];

    % trial在有效的trials对应的索引idx, 
    % 创建一个变量保存处理过后的眼动数据， 以视角为单位
    ETidx=0; 
    eyeData_deg={};

    % 计算性别指数类型(gender index)
    clear tempdata; clear temp_sti; clear unique_sti;
    j = 0;
    for i=1:length(trialsParams)
        j = j+1;
        params = trialsParams{i};
        if ~(isfield(params, 'calibPage') || isfield(params, 'noReport') || ...
                (isfield(params, 'testMode') && params.testMode ~= "false") ||...
                (params.trialResult ~= "Success" && params.trialResult ~= "ERR_WRONG_CHOICE"))
        tempdata=params.gender;
        temp_sti(j,1)=str2num(tempdata);
        end
    end% for i
    unique_sti=munique(temp_sti)'; % 计算出性别指数类型
    gndIdxRep=unique_sti; % 准备统计idx trial是第几个repit
    gndIdxRep(2,size(unique_sti,2))=zeros;
    %% 初始化结束



    %% 分析部分开始
    % 依次处理所有trials
    % fprintf('\n模块1: 处理所有trial开始\n');
    numIds = length(trialIds);
    for idx = 1: numIds
        tid = trialIds(idx);
        params = trialsParams{tid};
        %% 检查测试trial是否满足必须条件: ,
       
        if isfield(params, 'calibPage') || isfield(params, 'noReport') || ... % 忽略眼动校准的trial,忽略noReport的trial
            (isfield(params, 'testMode') && params.testMode ~= "false") ||...  % 忽略testMode的trial
            (params.trialResult ~= "Success" && params.trialResult ~= "ERR_WRONG_CHOICE")  % 忽略不是Success或WrongChoice的trial
            infostr = string(params.pageName);
            if isfield(params, 'pageTag')
                infostr = infostr + "," + string(params.pageTag);
            end
            if isfield(params, 'trialResult')
                infostr = infostr + "," + string(params.trialResult);
            end
            % fprintf('\nInvalid trial(%d), %s', tid, infostr);

            % 将无用的试次保存
            nonUse_tid=[nonUse_tid tid];
            continue;
        end
        %%


        %% 得到眼动校准的参数
        [leftEyeUsed, eyeOffsetX, eyeOffsetY, eyeGainX, eyeGainY, eyeCouplingX, eyeCouplingY] = ...
            helper.processEyeParams(leftIsPrimaryEye, params.leftEyeCalib, params.rightEyeCalib);
        if leftEyeUsed
            posX = posLeftX;
            posY = posLeftY;
        else
            posX = posRightX;
            posY = posRightY;
        end
        %%


        %% step1: prepare [rawTrialData], gaze data converted to screen position in cm
        data=trialsData{tid};
        rawTrialData=double([data(1+posX:numAnalog:end)', data(1+posY:numAnalog:end)']);
        rawTrialData=[(rawTrialData(:,1)-eyeOffsetX)*eyeGainX + (rawTrialData(:,2)-eyeOffsetY)*eyeCouplingY, ...
            (rawTrialData(:,2)-eyeOffsetY)*eyeGainY + (rawTrialData(:,1)-eyeOffsetX)*eyeCouplingX];
        %flip y value
        rawTrialData(:,2) = -rawTrialData(:,2);

        [rawTrialData, frameOn_time]=effectSamples(tid, rawTrialData, trialsEvents); % FTH添加，抽提出仅在刺激出现时采样数据
        
        if isempty(rawTrialData)
            fprintf('effectDataEmpty');
            nonUse_tid=[nonUse_tid tid];
            continue;
        end

        %------------------------------------------------------------------
        % 该部分稍作改动，因为先滤波后处理眼动数据效果更好，故变量之间输入输出顺序有所更改(FTH)
        %% GA-ILAB job start
        % step2: filter processing, get [filteredTrialData]

        filterWin = eval([eye.AP.filter.method, '(', eye.AP.filter.param1, eye.AP.filter.param2, ')']);
        filteredTrialData = [GA_ilabFilter(filterWin, 1, rawTrialData(:,1)), GA_ilabFilter(filterWin, 1, rawTrialData(:,2))];

        if isempty(filteredTrialData)
            fprintf('filteredTrialDataEmpty');
            nonUse_tid=[nonUse_tid tid];
            continue;
        end
        
        ETidx=ETidx+1;
        %% 生成二项迫选结果分类
        % 找到选择结果索引，8为左，9为右。
        tmpChioceIdx = find(trialsEvents{1,tid}.eventid == 8 | trialsEvents{1,tid}.eventid == 9);

        % 结果
        if trialsEvents{1,tid}.eventid(tmpChioceIdx) == 8
            tmpChoice = -1;
        elseif trialsEvents{1,tid}.eventid(tmpChioceIdx) == 9
            tmpChoice = 1;
        end

        % 判断生成选择结果表
        if ~exist('choice', 'var')
            choice = [];
        end
        choice =[choice, tmpChoice];
        %%

        frameOn(1,ETidx) = frameOn_time;
        

        % step3: blink processing, get [nonBlinkTrialData]
        [nonBlinksData, interplaData] = BMA_calcBlinks(filteredTrialData, tid); % FTH添加，利用速率和eyelink数据特性判定blink filteredTrialData
%         blinkList  = GA_ilabMkBlinkList(filteredTrialData, [1, size(filteredTrialData, 1)], eye.AP.blink);
%         nonBlinkTrialData = GA_ilabFilterBlinks(filteredTrialData, blinkList);

        nonBlinksTrialsData{1,ETidx} = nonBlinksData;
        interplaTrialsData{1,ETidx} = interplaData;
        

        % step4: fixation processing, get [fixList]
        fixList = GA_ilabMkFixationList(tid, nonBlinksData);
        [fixTable, fixTitle] = GA_ilabMkFixationTbl(fixList, 'spreadsheet');
        fixation_list=[fixation_list; fixList]; % 保存所有的盯视计算信息

        % step5: saccade processing, get [saccadeList]
        saccadeList = GA_ilabMkSaccadeList(tid, nonBlinksData);
        [saccadeTable, saccadeTitle] = GA_ilabMkSaccadeTbl(saccadeList, 'spreadsheet');
        saccade_list=[saccade_list; saccadeList];

        % % 临时
        % [nonChoiceTraceData] = calcChoiceTrace(nonBlinksData, fixList, screen, tmpChoice);
        % nonChoicetrialsData{1,ETidx} = nonChoiceTraceData;

        % 临时功能：总和处理好的眼动数据，并在第二部分进行分类输出 2024.11.19
        filteredTrialData_deg=zeros(size(nonBlinksData)); % 预分配内存
        for tempEyeDataIdx = 1:size(nonBlinksData, 1)
            filteredTrialData_deg(tempEyeDataIdx, 1)=unitChange('cm2deg', 'H', nonBlinksData(tempEyeDataIdx, 1), screen);
            filteredTrialData_deg(tempEyeDataIdx, 2)=unitChange('cm2deg', 'V', nonBlinksData(tempEyeDataIdx, 2), screen);
        end
        eyeData_deg{1,ETidx}=filteredTrialData_deg;  
        %% GA-ILAB job end


        %% 写入数据
        %------------------------------------------------------------------
        if exist('outputDir',"var") == 1
            % 结果写入txt文件
            if ~headerOK
                fwrite(fid_fix, fixTitle, 'char');
                fwrite(fid_saccade, saccadeTitle, 'char');
                headerOK = 1;
            end
            if ~isempty(fixTable)
                fwrite(fid_fix, cat(2,fixTable{:}), 'char');
            end
            if ~isempty(saccadeTable)
                fwrite(fid_saccade, cat(2,saccadeTable{:}), 'char');
            end
        end
        %%
        

        %% 生成文件命名信息
        % 性别指数
        gndIdx = str2double(trialsParams{1,idx}.gender); % 当前trial的gndidx
        if gndIdx < 0
            tmpGndPic = sprintf("|%.1f|",abs(gndIdx));
            tmpGndfile = sprintf("-%.1f",abs(gndIdx)); % 文件命名时绝对值符号无效
        elseif gndIdx >= 0
            tmpGndPic = sprintf("%.1f",gndIdx);
            tmpGndfile = sprintf("%.1f",gndIdx);
        end % if gndIdx

        % 性别指数重复
        whichGnd = find(gndIdxRep(1,:)==gndIdx);
        gndIdxRep(2, whichGnd) = gndIdxRep(2, whichGnd)+1; % 当前idx是某个gndIdx的第几个重复
        tmpGndRepit = string(gndIdxRep(2, whichGnd));

        % mode
        mode = trialsParams{1,tid}.mode;

        % 对错
        if strcmp(trialsParams{1,tid}.trialResult,'ERR_WRONG_CHOICE')
            tmpRslt="wro";
        elseif strcmp(trialsParams{1,tid}.trialResult,'Success')
            tmpRslt="corr";
        end % if strcmp
        %%

        %% 绘图
        if ismember(ETidx, seeds)
            BMA_drawEyeTrace(fixList, tmpGndPic, tmpGndfile, tmpGndRepit, tmpRslt, ETidx, mode, tid,...
                trialsParams, trialsFrames, interplaData, nonBlinksData, eye, ...
                eyeTrcRsltPath, nonChoiTrcRsltPath, trlFixsRsltPath, outputDir);
        end    
        %%


        %% 将每个有效的trial的原始索引，性别指数，正误对应放置
        % ------------------------------------------------
        % trlInfo=[oriTrlIdx; tmpGndIdx; tmpRepit；tmpRslt];
        % oriTrlIdx：有效试次的原始编码；有效编码就是长度索引
        % tmpGndIdx: 试次性别指数
        % tmpRepit: 性别指数的第几个重复
        % tmpRslt: 试次正误
        % ------------------------------------------------
        % 原始试次编码
        trlInfo(1,ETidx)=tid;
        % 性别指数
        tmpGndIdx = str2num(trialsParams{tid}.gender);
        trlInfo(2,ETidx) = tmpGndIdx;
        % 性别指数重复
        tmpRepit= gndIdxRep(2, whichGnd);
        trlInfo(3,ETidx) = tmpRepit;
        % 正误
        if strcmp(trialsParams{1,tid}.trialResult,'ERR_WRONG_CHOICE')
            tmpRslt = 0;
        elseif strcmp(trialsParams{1,tid}.trialResult,'Success')
            tmpRslt = 1;
        end % if strcmp
        trlInfo(4,ETidx) = tmpRslt;
        %% 
      

    end % for idx (循环所有trial)
    
    % 关闭存储fix, sacc的.txt文件
    if exist('outputDir',"var") == 1
        fclose(fid_fix);
        fclose(fid_saccade);
    end


    %% 生成性别指数与有效、原始试次、trial正误及正确率对应表
    % ---------------------------------------------------------
    % gndIdx_trls{} = {unique_sti; tmpTrlsIdx', tmpTrlsRslt'; tmpOriTrlsIdx' , tmpTrlsRslt'; tmpCorrRate}
    % unique_sti: 性别指数
    % tmpTrlsIdx': 有效试次索引
    % tmpOriTrlsIdx': 原始试次索引
    % tmpTrlsRslt': 试次对应结果
    % tmpCorrRate: 性别指数对应的正确率
    % ---------------------------------------------------------
    gndIdx_trls = {};
    for gndIdx=1:length(unique_sti)

        % 有效试次索引
        tmpTrlsIdx = find(trlInfo(2,:) == unique_sti(gndIdx));

        % 原始试次索引
        tmpOriTrlsIdx = trlInfo(1, tmpTrlsIdx);

        % 试次对应的正误
        tmpTrlsRslt = trlInfo(4,tmpTrlsIdx);

        % 性别指数对应的正确率
        tmpCorrRate=sum(tmpTrlsRslt / length(tmpTrlsRslt));


        % 对应性别指数进行存储
        % 先存储性别指数
        gndIdx_trls{1, gndIdx} = unique_sti(gndIdx);

        % 有效试次，正误
        gndIdx_trls{2, gndIdx} = tmpTrlsIdx';
        gndIdx_trls{2, gndIdx}(:, 2) = tmpTrlsRslt';

        % 原始试次，正误
        gndIdx_trls{3, gndIdx} = tmpOriTrlsIdx';
        gndIdx_trls{3, gndIdx}(:, 2) = tmpTrlsRslt';

        % 性别指数对应的正确率
        gndIdx_trls{4, gndIdx} = tmpCorrRate;

    end % for GndIdx
    %%
    

    
    
    

    %% 分析部分结束


    
    %% 数据输出部分
    if saveRsltIdx == 1

    % 整理需要保存的数据 
    % 创建输出的struct
    structName=strcat('file', extractAfter(name, '-r'));
    savDta.(structName) = struct();
    
    % 拿出有效的trials对应cfb的原始Idx
    effTrlIdx=trialIds(~ismember(trialIds, nonUse_tid));

    % 拿出有效的trials的数据
    effEvents=trialsEvents(effTrlIdx);
    effFrames=trialsFrames(effTrlIdx);
    effParams=trialsParams(effTrlIdx);

    % 找到该sub-block的mode
    switch str2num(trialsParams{1,effTrlIdx(1)}.mode)
        case 0
            modeId=0;
            modeName='free search';

        case 1
            modeId=1;
            modeName='fixation enforce';

        case 2
            modeId=2;
            modeName='reaction time';
    end
    
    % 做原始数据更改
    [effParams] = cfbParamsChange(effParams);

    %% PLW frame mat2py readable format
    [pyFrm] = GA_PLWframe_mat2py(effFrames);
    
    %% frame convert end

    %% store required data

    % mode ID & name
    savDta.mode.modeName=modeName;
    savDta.mode.modeId=modeId;
    
    % experiment data
    % eye data, unit: cm
    savDta.trialsData.eyeData_cm.nonBlinksData = nonBlinksTrialsData; % nan数据
    savDta.trialsData.eyeData_cm.interplaData = interplaTrialsData; % 插值数据
    % savDta.trialsData.eyeData_cm.nonChoiceTraceData = nonChoicetrialsData; % 无选择行为数据
    % 眼动数据deg
    savDta.trialsData.eyeData_deg = eyeData_deg;
    % 其他相关数据
    savDta.frameOnTime = frameOn;
    savDta.screen = screen;
    savDta.trlInfo = trlInfo;
    savDta.unique_sti = unique_sti;
    savDta.gndIdx_trls = gndIdx_trls;
    savDta.choice = choice;
    savDta.testParams = testParams;
    savDta.effTrlIdx = effTrlIdx;
    savDta.trialsEvents = effEvents;
    savDta.trialsFrames = effFrames;
    savDta.trialsParams = effParams;
    savDta.saccadeList = saccade_list;
    savDta.fixationList = fixation_list;
    savDta.pyFrm = pyFrm;

    % 保存所需要的数据
    structName = char(structName);
    eval([structName ' = savDta;']);
    savDtaPath=fullfile(trlsRsltPath,strcat(name,'-eyeTrcAnlyz.mat'));
    save(savDtaPath, structName, '-v7');

    fprintf('\n 文件"%s"处理结束\n', name);

    %% store end

    end % if saveRsltIdx == 1
    %% 数据输出结束

    
    
end % main func lvtDataBM_trial()