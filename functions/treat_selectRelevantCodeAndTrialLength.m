function [rel_code, trialLength] = treat_selectRelevantCodeAndTrialLength(codes, startTimes, samplingRate)
% This file is part of the TREAT Toolbox V1.0
% Copyright © 2026 University Medical Center Utrecht 
% Main Authors: Mariana P Branco, Simon Geukes   

% Validate input lengths
    if length(codes) ~= length(startTimes)
        error('codes and startTimes must have the same length.');
    end

    % Convert samples to seconds
    timeSec = startTimes / samplingRate;
    uniqueCodes = unique(codes);

    %% Step 1: GUI for code selection
    f = figure('Name', 'Select Active Cue', 'Position', [300 300 400 250]); % Compact GUI

    % Title
    uicontrol(f, 'Style', 'text', 'Position', [20 200 360 30], ...
        'String', 'Select the relevant code', ...
        'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

    % Message
    msg = sprintf(['TREAT found the following unique codes:\n%s\n' ...
                   'Select the code to consider the active cue:'], ...
                   num2str(uniqueCodes));
    uicontrol(f, 'Style', 'text', 'Position', [20 140 360 50], ...
        'String', msg, 'HorizontalAlignment', 'left');

    % Dropdown menu
    codeMenu = uicontrol(f, 'Style', 'popupmenu', 'Position', [20 110 100 25], ...
        'String', cellstr(num2str(uniqueCodes(:))), 'Value', 1);

    % Submit button
    uicontrol(f, 'Style', 'pushbutton', 'Position', [20 50 100 40], 'String', 'Submit', ...
        'FontWeight', 'bold', 'Callback', @(src, event) submitCallback());

    % Separate figure for plot
    figPlot = figure('Name', 'Code Occurrences Over Time', 'Position', [750 300 600 400]);
    scatter(timeSec, codes, 'filled');
    xlabel('Time (s)');
    ylabel('Code');
    title('Code Occurrences Over Time');
    grid on;

    uiwait(f);

    function submitCallback()
        selectedIndex = codeMenu.Value;
        rel_code = uniqueCodes(selectedIndex);

        % Check intervals for selected code
        idx = (codes == rel_code);
        relTimes = timeSec(idx);
        diffs = diff(relTimes);

        if any(diffs < 1.5) 
            errordlg('Error: Some intervals between occurrences are shorter than 1.5 seconds.', 'Interval Check');
            return; % Do not proceed
        end

        % Store stats for next GUI
        assignin('base', 'medianInterval', median(diffs));
        assignin('base', 'occurrences', numel(relTimes));

        uiresume(f);
        close(f);
        close(figPlot);
    end

    %% Step 2: GUI for trial length
    medianInterval = evalin('base', 'medianInterval');
    occurrences = evalin('base', 'occurrences');

    g = figure('Name', 'Trial Length', 'Position', [600 600 400 180]);
    uicontrol(g, 'Style', 'text', 'Position', [20 100 360 60], ...
        'String', sprintf(['Selected code occurs %d times.\n' ...
                           'Median interval: %.2f s\n' ...
                           'Enter desired trial length (seconds):'], ...
                           occurrences, medianInterval), ...
        'HorizontalAlignment', 'left');
    trialInput = uicontrol(g, 'Style', 'edit', 'Position', [20 50 100 25], 'String', '1.5');
    uicontrol(g, 'Style', 'pushbutton', 'Position', [150 50 100 30], 'String', 'OK', ...
        'Callback', @(src, event) submitTrial());
    uiwait(g);

    function submitTrial()
        trialLength = str2double(trialInput.String);
        if isnan(trialLength) || trialLength <= 0
            errordlg('Please enter a valid positive number.', 'Input Error');
            return;
        end
        uiresume(g);
        close(g);
    end
end