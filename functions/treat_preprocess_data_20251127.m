function [signal_out, time_vector_ds, event_vector_ds, target_fs] = treat_preprocess_data_20251127(signal_in, sampling_rate, event_vector, notch_base_freq,channelSelection)
% PREPROCESS_TREAT_DATA Applies standard preprocessing to ECoG signal and preserves cue events during downsampling.
% Adds a GUI for channel selection (based on RMS visualization).
%
% Inputs:
%   signal_in       - channels × time matrix of raw signals
%   sampling_rate   - sampling rate in Hz
%   event_vector    - 1 × time binary vector marking cue events
%   notch_base_freq - base frequency for notch filtering (50 or 60 Hz)
%
% Outputs:
%   signal_out      - preprocessed signal matrix (selected channels only)
%   time_vector_ds  - downsampled time vector
%   event_vector_ds - downsampled binary event vector
%   target_fs       - target sampling rate (250 Hz)

    % Validate inputs
    if ~ismatrix(signal_in)
        error('Input signal must be a 2D matrix.');
    end
    if ~isscalar(sampling_rate) || sampling_rate <= 0
        error('Sampling rate must be a positive scalar.');
    end
    if ~isscalar(notch_base_freq) || ~ismember(notch_base_freq, [50, 60])
        error('Notch base frequency must be either 50 or 60 Hz.');
    end

    %% Step 0: RMS visualization and channel selection
    % rmsValues = rms(signal_in'); % RMS per channel
    % figure('Name', 'Channel RMS', 'Position', [300 300 800 500]);
    % bar(rmsValues);
    % xlabel('Channels');
    % ylabel('RMS Amplitude');
    % title('RMS of Raw Signal per Channel');
    % grid on;

    % GUI for channel selection
    %selectedChannels = channelSelectionGUI(size(signal_in, 1));

    % Keep only selected channels
    signal_in = signal_in(channelSelection, :);

    %% Step 1: Common average rereferencing
    signal_in = signal_in - mean(signal_in, 1);

    %% Step 2: Bandpass filter (Butterworth)
    [b, a] = butter(3, [0.15 120] / (sampling_rate / 2), 'bandpass');
    signal_bp = filtfilt(b, a, signal_in')';

    %% Step 3: Notch filtering at harmonics ±1 Hz
    harmonics = notch_base_freq:notch_base_freq:120;
    signal_notch = signal_bp;
    for f = harmonics
        [b, a] = butter(4, [(f-1) (f+1)] / (sampling_rate / 2), 'stop');
        signal_notch = filtfilt(b, a, signal_notch')';
    end

    %% Step 4: Downsample to 250 Hz
    target_fs = 250;
    [p, q] = rat(target_fs / sampling_rate);
    signal_out = resample(signal_notch', p, q)';

    %% Step 5: Downsample time vector
    n_timepoints = size(signal_in, 2);
    time_vector = (0:n_timepoints-1) / sampling_rate;
    time_vector_ds = linspace(0, time_vector(end), size(signal_out, 2));

    %% Step 6: Preserve cue events during downsampling
    cue_indices = find(event_vector == 1);
    cue_times = time_vector(cue_indices);
    event_vector_ds = zeros(1, length(time_vector_ds));
    for i = 1:length(cue_times)
        [~, idx] = min(abs(time_vector_ds - cue_times(i)));
        event_vector_ds(idx) = 1;
    end
end

