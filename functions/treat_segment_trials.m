function [active_data, rest_data, traces] = segment_treat_trials_simple(av_processed_signal, event_vector, fs, win_sec)
%SEGMENT_TREAT_TRIALS_SIMPLE
% Segment into [channels x time x trials] with a combined trace per trial.
% - Active and rest segment lengths are fixed by time (default 1s)
% - Requires sampling rate fs (Hz)
% - Assumes av_processed_signal is [time x channels]
% - Uses rising-edge cue detection
% - Keeps only complete segments (no padding)
%
% Inputs:
%   av_processed_signal : [T x C]
%   event_vector        : [T x 1] logical or numeric (cue > 0)
%   fs                  : sampling rate in Hz (required)
%   win_sec             : segment length in seconds (optional, default = 1)
%
% Outputs:
%   active_data : [C x L  x N] (from cue to cue+L-1)
%   rest_data   : [C x L  x N] (from cue-L to cue-1)
%   traces      : [C x 2L x N] ([rest, active] concatenated along time)

    % ----- Args & basic validation -----
    if nargin < 3
        error('Please provide sampling rate fs (Hz).');
    end
    if nargin < 4 || isempty(win_sec)
        win_sec = 1.5; % default 1 second
    end

    if ~isscalar(fs) || fs <= 0
        error('fs must be a positive scalar (Hz).');
    end
    if ~isscalar(win_sec) || win_sec <= 0
        error('win_sec must be a positive scalar (seconds).');
    end

    % Segment length in samples
    L = max(1, round(fs * win_sec));

    % Dimensions
    [T, C] = size(av_processed_signal);

    % ----- Detect cue onsets (rising edges) -----
    ev = event_vector(:) > 0;
    cue_indices = find(diff([false; ev]) == 1);

    if isempty(cue_indices)
        active_data = zeros(C, L, 0);
        rest_data   = zeros(C, L, 0);
        traces      = zeros(C, 2*L, 0);
        return;
    end

    % ----- Build segment bounds -----
    a_start = cue_indices;
    a_end   = cue_indices + L - 1;
    r_start = cue_indices - L;
    r_end   = cue_indices - 1;

    % ----- Keep only complete segments -----
    valid = (a_end <= T) & (r_start >= 1);
    vi = find(valid);
    N  = numel(vi);

    if N == 0
        active_data = zeros(C, L, 0);
        rest_data   = zeros(C, L, 0);
        traces      = zeros(C, 2*L, 0);
        return;
    end

    % Preallocate
    active_data = zeros(C, L,   N);
    rest_data   = zeros(C, L,   N);
    traces      = zeros(C, 2*L, N);

    % Fill outputs
    for n = 1:N
        i = vi(n);
        AS = a_start(i); AE = a_end(i);
        RS = r_start(i); RE = r_end(i);

        rest_seg   = av_processed_signal(RS:RE, :)';  % [C x L]
        active_seg = av_processed_signal(AS:AE, :)';  % [C x L]

        rest_data(:,:,n)   = rest_seg;
        active_data(:,:,n) = active_seg;

        traces(:, 1:L,       n) = rest_seg;
        traces(:, L+1:2*L,   n) = active_seg;
    end
end