function [startTime, endTime] = treat_neuralSlopeGUI(trialLength)
% This file is part of the TREAT Toolbox V1.0
% Copyright © 2026 University Medical Center Utrecht 
% Main Authors: Mariana P Branco, Simon Geukes    

% Create the GUI window
    fig = uifigure('Name', 'Neural Slope Marker Time Range', 'Position', [100 100 400 250]);

    % Start time label and input
    uilabel(fig, 'Position', [50 180 100 22], 'Text', 'Start Time:');
    startField = uieditfield(fig, 'numeric', 'Position', [160 180 100 22]);

    % End time label and input
    uilabel(fig, 'Position', [50 140 100 22], 'Text', 'End Time:');
    endField = uieditfield(fig, 'numeric', 'Position', [160 140 100 22]);

    % Status message
    statusLabel = uilabel(fig, 'Position', [50 60 300 22], 'Text', '', 'FontColor', 'red');

    % Submit button
    uibutton(fig, 'Position', [150 100 100 30], 'Text', 'Submit', ...
        'ButtonPushedFcn', @(btn,event) onSubmit());

    % Pause execution until user submits
    uiwait(fig);

    % Output variables (set in nested function)
    function onSubmit()
        s = startField.Value;
        e = endField.Value;

        if isempty(s) || isempty(e)
            statusLabel.Text = 'Please enter both start and end times.';
        elseif s <= 0
            statusLabel.Text = 'Start time must be greater than 0.';
        elseif s >= e
            statusLabel.Text = 'Start time must be less than end time.';
        elseif e >= trialLength
            statusLabel.Text = sprintf('End time must be less than trialLength (%.2f).', trialLength);
        else
            statusLabel.Text = 'Valid time range selected.';
            statusLabel.FontColor = [0 0.5 0]; % green

            % Assign outputs and close GUI
            startTime = s;
            endTime = e;
            uiresume(fig);
            delete(fig);
        end
    end
end