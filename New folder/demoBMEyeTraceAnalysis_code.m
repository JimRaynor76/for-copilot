%% BioMotion Eye Trace Analysis Script
% This script performs eye trace analysis for BioMotion experiments without GUI
% Supports processing single files, multiple files, or all files in a directory

%% CONFIGURATION - Edit these parameters as needed

% Processing mode:
% 'single' - Process a single file specified by dataFilePath
% 'list'   - Process a list of files specified in dataFilePaths
% 'folder' - Process all .cfb files in the folderPath
processingMode = 'single'; % Choose one: 'single', 'list', or 'folder'

% For 'single' mode - specify a single file path
dataFilePath = "Z:\from other\Wang_JW\wjw data\20251119\2025-11-19(122)-r0006.cfb";

% For 'list' mode - specify a cell array of file paths
dataFilePaths = {
    "E:\BioMotionPreprocessing\data\2025-04-07(122)-r0016.cfb",
    "E:\BioMotionPreprocessing\data\2025-04-07(122)-r0016.cfb",
    "E:\BioMotionPreprocessing\data\2025-04-07(122)-r0016.cfb"
};

% For 'folder' mode - specify folder containing .cfb files
folderPath = "Z:\BioMotionAnlyze\lvtload\originData\202511_typeB";

% Set the output directory (replace with your output directory)
% outputDir = "Z:\BioMotionAnlyze\analyze\raw_data";
outputDir = "Z:\from other\Shi_YY\fromsyy\test";


% Set trial IDs to analyze. Use [-1] for all trials, or specify trial numbers
trialIds = [-1]; % e.g., [12:14, 23:25] for trials 12,13,14,23,24,25

%% ANALYSIS PARAMETERS

% ---- BLINK DETECTION PARAMETERS ----
blinkLeft = -20;        % deg
blinkRight = 20;        % deg
blinkDown = -20;        % deg
blinkUp = 20;           % deg
blinkVertThresh = 0.9;  % deg/ms
blinkWindow = 80;       % ms

% ---- FIXATION DETECTION PARAMETERS ----
% Note: fixMinDuration should be between 100-300ms
% Note: fixDisp should be around 2.5 degrees
% Higher fixMinDuration may cause fix points to be ignored
% Lower fixMinDuration may cause over-counting of fixations
% Higher fixDisp may cause fixpoint position offset
% Lower fixDisp may cause over-counting of fixations
fixDisp = 2.2;          % deg
fixMinDuration = 200;   % ms

%% DATA PROCESSING
try
    % Create array of files to process based on mode
    filesToProcess = {};
    
    switch lower(processingMode)
        case 'single'
            % Process a single file
            if ~exist(dataFilePath, 'file')
                error('Input file does not exist: %s', dataFilePath);
            end
            filesToProcess{1} = dataFilePath;
            
        case 'list'
            % Process a list of files
            % Validate each file in the list
            for i = 1:length(dataFilePaths)
                if ~exist(dataFilePaths{i}, 'file')
                    warning('File does not exist and will be skipped: %s', dataFilePaths{i});
                else
                    filesToProcess{end+1} = dataFilePaths{i}; %#ok<SAGROW>
                end
            end
            if isempty(filesToProcess)
                error('No valid files found in the provided list');
            end
            
        case 'folder'
            % Process all .cfb files in a folder
            if ~exist(folderPath, 'dir')
                error('Folder does not exist: %s', folderPath);
            end
            
            % Get all .cfb files in the folder
            folderFiles = dir(fullfile(folderPath, '*.cfb'));
            if isempty(folderFiles)
                error('No .cfb files found in folder: %s', folderPath);
            end
            
            for i = 1:length(folderFiles)
                filesToProcess{i} = fullfile(folderPath, folderFiles(i).name); %#ok<SAGROW>
            end
            
        otherwise
            error('Invalid processing mode. Use ''single'', ''list'', or ''folder''');
    end
    
    % Check if the output directory exists, create if needed
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
        fprintf('Created output directory: %s\n', outputDir);
    end
    
    % Initialize global analysis parameters once before processing files
    fprintf('Setting up eye tracking analysis parameters...\n');
    GA_ilabAnalysisParms();
    
    % Set blink and fixation parameters
    global eye;
    eye.APdeg.blink.limits = [blinkLeft, blinkRight, blinkDown, blinkUp];
    eye.APdeg.blink.vertThresh = blinkVertThresh;
    eye.APdeg.blink.window = blinkWindow;
    
    eye.APdeg.fix.params.disp.Disp = fixDisp;
    eye.APdeg.fix.params.disp.minDuration = fixMinDuration;
    
    % Process each file
    totalFiles = length(filesToProcess);
    fprintf('\nFound %d file(s) to process\n', totalFiles);
    
    % Save current directory to return to it later
    currentDir = pwd;
    
    % Set current directory to output directory for saving results
    cd(outputDir);
    
    % Create a log file to track processing results
    logFileName = fullfile(outputDir, ['processing_log_' datestr(now, 'yyyymmdd_HHMMSS') '.txt']);
    logFileID = fopen(logFileName, 'w');
    fprintf(logFileID, 'BioMotion Eye Trace Analysis Processing Log\n');
    fprintf(logFileID, 'Started: %s\n\n', datestr(now));
    
    % Process each file
    successCount = 0;
    skippedCount = 0;
    errorCount = 0;
    
    for fileIdx = 1:totalFiles
        currentFile = filesToProcess{fileIdx};
        [~, fileName, ~] = fileparts(currentFile);
        
        fprintf('\n==================================\n');
        fprintf('Processing file %d of %d: %s\n', fileIdx, totalFiles, fileName);
        fprintf(logFileID, '\nFile %d of %d: %s\n', fileIdx, totalFiles, currentFile);
        
        try
            % Load the data
            fprintf('Loading data...\n');
            [testParams, trialCnt, trialsParams, trialsData, trialsEvents, ...
             trialsCmds, trialsFrames, trialsCounters] = loadlvtdata(currentFile);
            
            % Verify protocol is BioMotion (122)
            protocol = str2double(testParams.protocol)';
            if (protocol(1) ~= 122)
                warning('Protocol BioMotion(122) expected, but found (%s). Skipping file.', num2str(protocol));
                fprintf(logFileID, '  SKIPPED: Protocol BioMotion(122) expected, but found (%s)\n', num2str(protocol));
                skippedCount = skippedCount + 1;
                continue;
            end
            
            fprintf('File loaded successfully. Protocol: %d\n', protocol(1));
            fprintf('Number of trials: %d\n', trialCnt);
            fprintf(logFileID, '  Protocol: %d, Number of trials: %d\n', protocol(1), trialCnt);
            
            % Run the analysis
            fprintf('Analyzing data for trials: %s\n', mat2str(trialIds));
            fprintf(logFileID, '  Analyzing trials: %s\n', mat2str(trialIds));
            
            % Run the analysis directly in the main output directory
            % lvtDataBM_trial(currentFile, trialIds, 1);
            lvtDataBM_trial_code(currentFile, trialIds, 1, outputDir);
            
            fprintf('Analysis completed for %s\n', fileName);
            fprintf(logFileID, '  SUCCESS: Analysis completed\n');
            successCount = successCount + 1;
            
        catch e
            % Catch errors for individual files, but continue processing others
            fprintf('ERROR processing %s: %s\n', fileName, e.message);
            fprintf(logFileID, '  ERROR: %s\n', e.message);
            % Log stack trace to file but not to console
            for j = 1:length(e.stack)
                fprintf(logFileID, '    %s (line %d)\n', e.stack(j).name, e.stack(j).line);
            end
            errorCount = errorCount + 1;
            
            % Return to output directory in case of error
            cd(outputDir);
            continue;
        end
    end
    
    % Write summary to log file
    fprintf(logFileID, '\n\nSUMMARY:\n');
    fprintf(logFileID, 'Total files: %d\n', totalFiles);
    fprintf(logFileID, 'Successfully processed: %d\n', successCount);
    fprintf(logFileID, 'Skipped: %d\n', skippedCount);
    fprintf(logFileID, 'Errors: %d\n', errorCount);
    fprintf(logFileID, '\nCompleted: %s\n', datestr(now));
    
    % Close log file
    fclose(logFileID);
    
    % Return to original directory
    cd(currentDir);
    
    % Display summary
    fprintf('\n==================================\n');
    fprintf('PROCESSING SUMMARY:\n');
    fprintf('Total files: %d\n', totalFiles);
    fprintf('Successfully processed: %d\n', successCount);
    fprintf('Skipped: %d\n', skippedCount);
    fprintf('Errors: %d\n', errorCount);
    fprintf('Results saved to: %s\n', outputDir);
    fprintf('Log file: %s\n', logFileName);
    
catch e
    % Display any errors that occur during the main processing
    fprintf('\nFATAL ERROR: %s\n', e.message);
    fprintf('Stack trace:\n');
    disp(e.stack);
    
    % Try to close log file if it was opened
    if exist('logFileID', 'var') && logFileID > 0
        fclose(logFileID);
    end
    
    % Try to return to the original directory if it was changed
    if exist('currentDir', 'var')
        cd(currentDir);
    end
end