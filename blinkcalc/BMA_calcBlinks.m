function [nonBlinkEyeData, intplaBlinkEyeData] = BMA_calcBlinks(eyeData, i)

% 计算真sacc
global eye;
ViewDist = eye.AP.screen.distance;
vThresh=ViewDist*80*pi/180; % vThresh:80°/s ---> unit: cm/s
vThresh_del=ViewDist*20*pi/180; % use 30°/s to delet blinks parts
bsbeWindow = 20; % unit ms, use a small time window to judge true blink start stop position
blinks=[];
tempx=eyeData(:,1);
tempy=eyeData(:,2);
vx=diff(tempx)*1000; vy=diff(tempy)*1000; % x,y velocity，unit:cm/s
vxy=sqrt(vx.^2 + vy.^2); % samples velocity

% % 绘制原始的眼动速度变化
% figure(20); set(20,'position',[400 200 800 600]);
% title_words=sprintf('trial%d Raw Eye Movement Veloctity Change',i);
% title(title_words);
% xlabel('Stimulus Presentation Duration (Ms)');
% ylabel('Velocity (Deg)'); hold on;
% plot(1:length(vxy),vxy,'Color',[1, 0.5,0]); hold on;
% cur_xlim=xlim;
% cur_ylim=ylim;
% axis([0 cur_xlim(2) -500 cur_ylim(2)]);
% pause(1); close(20);

index_blink=find(vxy>1000); % 用速率大于2000deg来寻找眨眼特征
if ~isempty(index_blink) % 如果index_blinks为空，则视为没有眨眼

    temp_blinks=[];
    j=index_blink(1);
    while j<max(index_blink)
        is=j;
        dur_blink=is+400; % 400ms blink window
        index_ie=max(find(index_blink<dur_blink)); % find last vxy point exceed 2000°/ms

        % if the blink is imcomplete
        if (index_blink(index_ie) - is) < 100 & (is + 150) > size(vxy,1)
            index_ie = size(vxy,1);
            index_blink = is:1:size(vxy,1);
            ie = size(vxy,1);
        else
            ie=index_blink(index_ie);
        end

        temp_blinks=[temp_blinks;i is ie];
        if ~(ie==max(index_blink))
            j=index_blink(index_ie+1);
        else
            j=ie;
        end % if
    end

    trialBlinksCnt=0;
    if ~isempty(temp_blinks)
        for k=1:length(temp_blinks(:,1))

            is=temp_blinks(k,2);
            ie=temp_blinks(k,3);

            for ks = is:-1:1
                if ks==1 % 如果向前索引到1，则第一个点即为眨眼点起始
                    bs=ks;
                elseif vxy(ks)<vThresh % find first v < 80°/s

                        bs=ks+1;
                        break

                end % if ks==
            end % for ks

            for ke=ie:length(vxy)
                if ke==length(vxy)
                    be=ke;
                elseif vxy(ke)<vThresh


                        be=ke-1;
                        break

                end % if ke==
            end %for ke


            % jugde a blink and delet
            % if (be-bs)>150 % if duration > 150 ms, we regard this as a blink

                for ks = bs:-1:1
                    if ks==1
                        bs_del=bs;
                    elseif vxy(ks)<vThresh_del % find first v < 80°/s

                        if ks - bsbeWindow < 1
                            tmp_bsv = vxy(1:ks);
                        else
                            tmp_bsv = vxy(ks-bsbeWindow:ks); % find true bs position
                        end


                        if ~isempty(find(tmp_bsv > vThresh_del))

                            tmp_bsIdx = min(find(tmp_bsv > vThresh_del));

                            if ks - bsbeWindow < 1
                                bs_del =  1 + tmp_bsIdx -1;
                                break

                            else
                                bs_del = ks - bsbeWindow + tmp_bsIdx -1;
                                break
                            end

                        else
                            bs_del=ks+1;
                            break
                        end

                    end % if ks==
                end % for bs

                for ke = be:length(vxy)
                    if ke==length(vxy)
                        be_del=ke;
                    elseif vxy(ke)<vThresh_del

                        if ke + bsbeWindow >length(vxy)
                            tmp_bev = vxy(ke : length(vxy));
                        else
                            tmp_bev = vxy(ke-bsbeWindow:ke);
                        end

                        if ~isempty(find(tmp_bev > vThresh_del))

                            tmp_beIdx = max(find(tmp_bev > vThresh_del));

                            if ke + bsbeWindow >length(vxy)
                                be_del = ke + tmp_beIdx;
                                break

                            else
                                be_del = ke + tmp_beIdx +1;
                                break
                            end

                        else
                            be_del=ke-1;
                            break
                        end
                    end % if ke==
                end %for ke

                trialBlinksCnt=trialBlinksCnt+1;
                blinks=[blinks; i trialBlinksCnt bs_del be_del];

            % end % if (be - bs)>150

        end % for k
    end % if ~isempty(temp_blinks)
end % if ~isempty(index_blink)

% 如果存在blinks，开始处理blinks
if ~isempty(blinks)

    % 以下采用两种方法处理眼动，一种直接将计算出的blinks去除(换成NaN)，后续用于计算；
    %另一种是利用高斯插值，后续用于画更好看的眼动轨迹图。

    %% 将blinks所在的数值去除
    locData=eyeData;

    for l=1:length(blinks(:,1))

        bs=blinks(l,3);
        be=blinks(l,4);

        locData(bs:be,:)=nan;

    end % for l

    % 去除blinks的眼动数据
    nonBlinkEyeData=locData;

    % 绘制去除blinks之后的眼动速率变化图
    % 计算速率
    new_tempx= nonBlinkEyeData(:,1);
    new_tempy= nonBlinkEyeData(:,2);
    new_vx=diff(new_tempx)*1000; new_vy=diff(new_tempy)*1000;
    new_vxy=sqrt(new_vx.^2 + new_vy.^2);

    % % 绘制
    % nonBlinksPic = figure('Name','nonBlinksTrc');
    % set(nonBlinksPic,'position',[200 100 800 600]);
    % title_words=sprintf('trial%d Before and After Remove Blinks Eye Movement Veloctity Change',i);
    % title(title_words);
    % xlabel('Stimulus Presentation Duration (Ms)');
    % ylabel('Velocity (Deg)'); hold on;
    % plot(1:length(vxy),vxy,'Color',[1, 0.5,0], 'DisplayName','Raw Data'); hold on;
    % plot(1:length(new_vxy),new_vxy,'Color','g','DisplayName','Calced Blinks Data'); legend show;
    % cur_xlim=xlim;
    % cur_ylim=ylim;
    % axis([0 cur_xlim(2) -500 cur_ylim(2)]);
    % pause(1); 
    % close(nonBlinksPic);
    %%

    %% 利用高斯插值替代blinks部分
    locData = eyeData;

    for l = 1:length(blinks(:,1))
  
        bs = blinks(l,3);
        be = blinks(l,4);

        % 找到区间生成插值
        if bs == 1
            bs = bs+1;
        end

        if be >= size(eyeData, 1)
            be = size(eyeData, 1 ) - 1;
        end

        x = [locData(bs-1,1), locData(be+1,1)];
        y = [locData(bs-1,2), locData(be+1,2)];
        xi = linspace(x(1), x(2), be-bs+1)';

        % 高斯分布参数
        mean_x = (x(1) + x(2)) / 2;
        sigma_x = abs(x(2) - x(1)) / 6;
        A_x = abs(x(2) - x(1)) / 2;
        gaussian = @(xi, mean_x, sigma_x, A_x) ...
            A_x * exp(-((xi - mean_x).^2) / (2 * sigma_x^2));

        % 生成高斯曲线
        yi_gaussian = gaussian(xi, mean_x, sigma_x, A_x);

        % 调整高斯曲线以匹配原始轨迹
        baseline = interp1(x, y, xi, 'linear');  % 线性插值基线
        y_final = yi_gaussian + baseline - min(yi_gaussian);  % 高斯曲线与基线组合

        % 替换原始眨眼段数据
        locData(bs:be,1) = xi;
        locData(bs:be,2) = y_final;       
       
    end

    % 插值替代blinks眼动数据
    intplaBlinkEyeData = locData;

    % % 绘制插值blinks之后的眼动速率变化图
    % % 计算速率
    new_tempx= nonBlinkEyeData(:,1);
    new_tempy= nonBlinkEyeData(:,2);
    new_vx=diff(new_tempx)*1000; new_vy=diff(new_tempy)*1000;
    new_vxy=sqrt(new_vx.^2 + new_vy.^2);

    % 绘制
    % intplaBlinksPic = figure('Name','intplaBlinks');
    % set(intplaBlinksPic,'position',[200 100 800 600]);
    % title_words=sprintf('trial%d Before and After Interpolation  Eye Movement Veloctity Change',i);
    % title(title_words);
    % xlabel('Stimulus Presentation Duration (Ms)');
    % ylabel('Velocity (Deg)'); hold on;
    % plot(1:length(vxy),vxy,'Color',[1, 0.5,0], 'DisplayName','Raw Data'); hold on;
    % plot(1:length(new_vxy),new_vxy,'Color','g','DisplayName','Calced Blinks Data'); legend show;
    % cur_xlim=xlim;
    % cur_ylim=ylim;
    % axis([0 cur_xlim(2) -500 cur_ylim(2)]);
    % pause(1);
    % close(intplaBlinksPic);
    %
     fprintf('\ntrial %d has blinks',i);

% 如果blinks不存在，则nonBlinksEyeData和intplaBlinkEyeData均为原始数据
else
    % 表明该试次不存在blinks
    % fprintf('\ntrial %d non blinks',i);

    % 赋值原始数据 
    nonBlinkEyeData = eyeData;
    intplaBlinkEyeData = eyeData;
end % if ~isempty(blinks)



end % func BMA_clacBlinks()