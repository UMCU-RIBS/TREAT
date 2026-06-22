function sfreq = samp_freq_input

% Ask user for the cue appearance time in seconds
prompt = {'Enter sampling frequency of the data (in Hz):'};
dlgtitle = 'Sampling frequency';
dims = [1 35];
definput = {'0'};  % Default to 0 seconds
answer = inputdlg(prompt, dlgtitle, dims, definput);

% Handle response
if isempty(answer)
    error('User cancelled input. Exiting.');
end

sfreq = str2double(answer{1});

% Validate the input
if isnan(sfreq) || sfreq < 0
    error('Invalid input. Sampling frequency must be a non-negative number.');
end

% Display the result
disp(['Data is sampled at ' num2str(sfreq) ' Hz.']);