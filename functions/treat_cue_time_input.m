function cue_time_sec = treat_cue_time_input

% Ask user for the cue appearance time in seconds
prompt = {'Enter cue appearance time (in seconds):'};
dlgtitle = 'Cue Time Input';
dims = [1 35];
definput = {'0'};  % Default to 0 seconds
answer = inputdlg(prompt, dlgtitle, dims, definput);

% Handle response
if isempty(answer)
    error('User cancelled input. Exiting.');
end

cue_time_sec = str2double(answer{1});

% Validate the input
if isnan(cue_time_sec) || cue_time_sec < 0
    error('Invalid input. Cue time must be a non-negative number.');
end

% Display the result
disp(['Cue appears at ' num2str(cue_time_sec) ' seconds.']);