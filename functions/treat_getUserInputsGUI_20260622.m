function userInputs = treat_getUserInputsGUI_20260622(treatFolder)
f = figure('Name', 'TREAT Toolbox Input', 'Position', [500 500 600 600]);


% Add TREAT logo tile (x,y,width,height in pixels)
logoPath = [treatFolder '/TREAT_20260210_logo.png']; 
addLogoToFigure(f, logoPath, [20 420 200 200]);  % top-left 


labelX = 40;
inputX = 270;
widthLabel = 200;
widthInput = 220;
height = 20;
yOffset = -50;   

% Title
uicontrol(f, 'Style', 'text', 'Position', [200 500+yOffset 300 30], ...
    'String', 'Welcome to the TREAT Toolbox!', ...
    'FontSize', 14, 'FontWeight', 'bold', 'ForegroundColor', [0 0.2 0.6]);


% Save Neural Slope Marker checkbox
uicontrol(f, 'Style', 'text', 'Position', [labelX 460+yOffset widthLabel height], ...
    'HorizontalAlignment', 'left', 'String', 'Save neural slope marker?');
saveNSM = uicontrol(f, 'Style', 'checkbox', 'Position', [inputX 460+yOffset 20 20], ...
    'Value', 0, 'TooltipString', 'Check to save the Neural Slope Marker output file');

% Run trial selection checkbox
uicontrol(f, 'Style', 'text', 'Position', [labelX 430+yOffset widthLabel height], ...
    'HorizontalAlignment', 'left', 'String', 'Run trial selection?');
trialSelection = uicontrol(f, 'Style', 'checkbox', 'Position', [inputX 430+yOffset 20 20], ...
    'Value', 1, 'TooltipString', 'Include the trials with the response to the task', ...
    'Callback', @(src, event) toggleTrialPercentage());

% Percentage of trials to include
trialPctLabel = uicontrol(f, 'Style', 'text', 'Position', [labelX 400+yOffset widthLabel height], ...
    'HorizontalAlignment', 'left', 'String', 'Percentage of trials to include:');
trialPctInput = uicontrol(f, 'Style', 'edit', 'Position', [inputX 400+yOffset widthInput height], ...
    'String', '50', 'TooltipString', 'Enter the percentage of trials to include');

% Channel selection
uicontrol(f, 'Style', 'text', 'Position', [labelX 370+yOffset widthLabel height], ...
    'HorizontalAlignment', 'left', 'String', 'Channel selection:');
channelSelection = uicontrol(f, 'Style', 'edit', 'Position', [inputX 370+yOffset widthInput height], ...
    'TooltipString', 'Enter channels to include (e.g., [1:3, 5]):');

% Subject name
uicontrol(f, 'Style', 'text', 'Position', [labelX 340+yOffset widthLabel height], ...
    'HorizontalAlignment', 'left', 'String', 'Subject name:');
subjectName = uicontrol(f, 'Style', 'edit', 'Position', [inputX 340+yOffset widthInput height], ...
    'String', '', 'TooltipString', 'Enter the subject identifier');

% Notch base frequency dropdown
uicontrol(f, 'Style', 'text', 'Position', [labelX 310+yOffset widthLabel height], ...
    'HorizontalAlignment', 'left', 'String', 'Notch base frequency:');
notchFreq = uicontrol(f, 'Style', 'popupmenu', 'Position', [inputX 310+yOffset 80 25], ...
    'String', {'50 Hz', '60 Hz'}, 'Value', 1, ...
    'TooltipString', 'Select the base frequency for notch filtering');



% Peak sign selection (Positive / Negative)
uicontrol(f, 'Style', 'text', 'Position', [labelX 280+yOffset widthLabel height], ...
    'HorizontalAlignment', 'left', 'String', 'Sign of the peak:');

peakSignPositive = uicontrol(f, 'Style', 'radiobutton', ...
    'Position', [inputX 280+yOffset 100 height], ...
    'String', 'Positive', 'Value', 1, ...
    'TooltipString', 'Select if the peaks of interest are positive', ...
    'Callback', @(src, event) setPeakSign('positive'));

peakSignNegative = uicontrol(f, 'Style', 'radiobutton', ...
    'Position', [inputX+110 280+yOffset 100 height], ...
    'String', 'Negative', 'Value', 0, ...
    'TooltipString', 'Select if the peaks of interest are negative', ...
    'Callback', @(src, event) setPeakSign('negative'));

% Default value
peakSign = 'positive';


% Feature of interest dropdown
uicontrol(f, 'Style', 'text', 'Position', [labelX 250+yOffset widthLabel height], ...
    'HorizontalAlignment', 'left', 'String', 'Feature of interest:');

featureOptions = { ...
    'High-frequency band', ...
    'Alpha band', ...
    'Beta band', ...
    'Local motor potential'};


featureDropdown = uicontrol(f, 'Style', 'popupmenu', ...
    'Position', [inputX 250+yOffset widthInput 25], ...
    'String', featureOptions, 'Value', 1, ...
    'TooltipString', 'Select the feature you want to extract');


% --- Small "i" help button with hover tooltip 
infoText = [ ...
    'High-frequency band: 65–95 Hz', newline, ...
    'Alpha band: 8–12 Hz', newline, ...
    'Beta band: 13–30 Hz', newline, ...
    'Local motor potential: causal moving average over 375 ms' ...
    ];

infoBtn = uicontrol(f, 'Style', 'pushbutton', ...
    'Position', [inputX + widthInput + 6, 250+yOffset + 4, 20, 20], ...
    'String', 'i', ...
    'ForegroundColor', [0 0.2 0.6], ...
    'TooltipString', infoText);

% File selection
uicontrol(f, 'Style', 'text', 'Position', [labelX 220+yOffset widthLabel height], ...
    'HorizontalAlignment', 'left', 'String', 'Select file:');
filePathDisplay = uicontrol(f, 'Style', 'edit', 'Position', [inputX 220+yOffset widthInput height], ...
    'Enable', 'inactive', 'TooltipString', 'Displays the selected file path');
uicontrol(f, 'Style', 'pushbutton', 'Position', [inputX 190+yOffset 150 25], 'String', 'Browse...', ...
    'TooltipString', 'Click to select a file', 'Callback', @(src, event) browseFile());

% Submit button
uicontrol(f, 'Style', 'pushbutton', 'Position', [inputX 130+yOffset 100 30], 'String', 'Submit', ...
    'TooltipString', 'Click to confirm and continue', 'Callback', @(src, event) submitCallback());

% Wait for user input
uiwait(f);

    function toggleTrialPercentage()
        if trialSelection.Value
            trialPctLabel.Visible = 'on';
            trialPctInput.Visible = 'on';
        else
            trialPctLabel.Visible = 'off';
            trialPctInput.Visible = 'off';
        end
    end

    function setPeakSign(choice)
        switch choice
            case 'positive'
                peakSign = 'positive';
                peakSignPositive.Value = 1;
                peakSignNegative.Value = 0;
            case 'negative'
                peakSign = 'negative';
                peakSignPositive.Value = 0;
                peakSignNegative.Value = 1;
        end
    end

    function browseFile()
        % Initialize filter list
        filterList = {};

        % Check for NSX loader
        if any(endsWith(which('openNSx', '-all'), '.m'))
            % Include all NSX file types (ns1 to ns9)
            filterList(end+1, :) = {'*.ns1;*.ns2;*.ns3;*.ns4;*.ns5;*.ns6;*.ns7;*.ns8;*.ns9', ...
                'Blackrock NSX files (*.ns1-*.ns9)'};
        end
        if any(endsWith(which('jun_readtrc', '-all'), '.m'))
            filterList(end+1, :) = {'*.trc', 'TRC files (*.trc)'};
        end
        if any(endsWith(which('load_bcidat', '-all'), '.m'))
            filterList(end+1, :) = {'*.dat', 'DAT files (*.dat)'};
        end

        % If no loaders are found, show warning and exit
        if isempty(filterList)
            warndlg('No compatible file loaders (.m files) found in path. File selection is disabled.', 'Loader Warning');
            return;
        end

        % defaultPath = '/Fridge/bci/data/bcipatients/mels/micromed/190610/';
        defaultPath = '/Fridge/bci/data/bcipatients/habe/micromed/habe110210/PAT_110/';
        [file, path, ~] = uigetfile(filterList, 'Select a compatible file', defaultPath);

        if isequal(file, 0)
            filePathDisplay.String = '';
        else
            filePathDisplay.String = fullfile(path, file);
            figure(f);  % Ensure GUI stays visible after file selection


            % Detect file type based on extension
            [~, ~, ext] = fileparts(file);
            ext = lower(ext);
            if startsWith(ext, '.ns')  % NSX files
                fileType = 'nsx';
            elseif strcmp(ext, '.trc')
                fileType = 'trc';
            elseif strcmp(ext, '.dat')
                fileType = 'dat';
            else
                fileType = 'unknown';
            end

            % Store in app data for later retrieval in submitCallback
            setappdata(f, 'selectedFileType', fileType);
        end
    end

    function submitCallback()
        % Validate subject name
        if isempty(strtrim(subjectName.String))
            errordlg('Subject name cannot be empty.', 'Input Error');
            return;
        end

        % Validate file path
        if isempty(strtrim(filePathDisplay.String))
            errordlg('Please select a data file before proceeding.', 'Input Error');
            return;
        end


        notchOptions = [50, 60];  % Map dropdown index to numeric values

        % Collect inputs
        userInputs.fileType = getappdata(f, 'selectedFileType');
        userInputs.saveNSM = logical(saveNSM.Value);
        userInputs.trialSelection = logical(trialSelection.Value);
        userInputs.trialPercentage = str2double(trialPctInput.String);
        try
            userInputs.channelSelection = parseMatlabRange(channelSelection.String);
        catch ME
            errordlg(ME.message, 'Input Error');
            return;
        end
        userInputs.subjectName = subjectName.String;
        userInputs.notchFrequency = notchOptions(notchFreq.Value);
        userInputs.FilePath = filePathDisplay.String;
        userInputs.peakSign = peakSign;
        userInputs.featureOfInterest = featureOptions{featureDropdown.Value};
        userInputs.treatFolder = treatFolder; 

        uiresume(f);
        close(f);
    end
end

function channelArray = parseMatlabRange(rangeStr)
%PARSEMATLABRANGE Safely evaluate MATLAB-style channel range strings.
% Example: '[1:3, 5]' -> [1 2 3 5]
% Throws error if invalid, reversed, or non-numeric.

rangeStr = strtrim(rangeStr);
if isempty(rangeStr)
    error('Channel range cannot be empty. Enter e.g., [1:3, 5].');
end

% Allow only digits, colons, commas, brackets, spaces
if ~isempty(regexp(rangeStr, '[^\d\s:\,\[\]]', 'once'))
    error('Invalid characters in channel range. Use MATLAB syntax like [1:3, 5].');
end

try
    val = eval(rangeStr);  % Evaluate MATLAB expression
catch
    error('Invalid channel range format. Use MATLAB syntax like [1:3, 5].');
end

if ~isnumeric(val)
    error('Channel range must evaluate to a numeric array.');
end

channelArray = unique(val(:)'); % Ensure row vector, remove duplicates

% Checks
if isempty(channelArray)
    error('Channel selection cannot be empty.');
end
if any(channelArray <= 0) || any(mod(channelArray,1) ~= 0)
    error('Channel indices must be positive integers.');
end
if any(diff(channelArray) < 0)
    error('Channel ranges must be ascending. Example: 1:10, not 99:1.');
end
end




function addLogoToFigure(figHandle, imgPath, pos)
%ADDLOGOTOFIGURE Display a logo in a borderless axes.

    if ~exist(imgPath, 'file')
        warning('Logo not found: %s', imgPath);
        return;
    end

    % Read PNG / JPG (alpha supported if present)
    [img, ~, alpha] = imread(imgPath);

    % Create axes for the image
    ax = axes('Parent', figHandle, ...
        'Units', 'pixels', ...
        'Position', pos, ...
        'Visible', 'off', ...
        'HitTest','off', ...
        'PickableParts','none');

    hIm = imshow(img, 'Parent', ax);
    axis(ax, 'image');

    % Use transparency if the image has alpha
    if exist('alpha','var') && ~isempty(alpha)
        set(hIm, 'AlphaData', double(alpha) / 255);
    end

    uistack(ax, 'top');
end
