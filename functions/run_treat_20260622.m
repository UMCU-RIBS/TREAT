function [nSlopemarker,peaks_all,min_all] =run_treat_20260622(data, codes, startTimes, sampling_rate,userInputs)
% First attempt at the function to run the TREAT toolbox
% SH Geukes, 2025

% set paths and set the stage
close all; clc
disp('Welcome to the TREAT toolbox!')
cd(userInputs.treatFolder)

% first check if dimensions are in order
% [1 x n_codes]
if size(codes,1)>size(codes,2)
    codes = codes';
end

%[channel x time]
if size(data,1)>size(data,2)
    data = data';
end 

%%% Select relevant code and trial length
[rel_code,trialLength] = treat_selectRelevantCodeAndTrialLength(codes,startTimes,sampling_rate);

%%% Create event matrix 
event_matrix = zeros(1,size(data,2));
rel_ev = codes == rel_code;
rel_samp = startTimes(rel_ev);
event_matrix(rel_samp) = 1; 

%%% Preprocess signal and event vector
disp('Preprocessing...')
[preprocessed_signal, ~, event_vector_ds,sfreq] = treat_preprocess_data_20251127( ...
    data, sampling_rate, event_matrix, userInputs.notchFrequency,userInputs.channelSelection);

%%% Prepare for Gabor (Zac's function)
feat_oi = userInputs.featureOfInterest;
fprintf('Extracting the %s...\n',lower(feat_oi))

if strcmp(feat_oi,'Local motor potential')
    
    windowsize = 0.375; %from Schalk et al., 2007; 
    [av_processed_signal,event_vector_ds] = treat_calculate_LMP(data,windowsize,sfreq,event_vector_ds); %with quick fix for the event vector. change later! 
else %extract power
    switch feat_oi
        case 'High-frequency band'
            spect_params.spectra = 65:95;
        case 'Alpha band'
            spect_params.spectra = 8:12;
        case 'Beta band'
            spect_params.spectra = 13:30;
    end
    spect_params.W = 4; % FWHM of the gaussian
    spect_params.sample_rate = sfreq; %frequency of the downsampled data

    processed_signal = treat_pt_gabor_cov_fitted(preprocessed_signal, spect_params, 'amp', 1, 0); % extract power info
    av_processed_signal = squeeze(mean(processed_signal, 3)); % average over frequency bands
end


%%% Segment trials into 3D arrays [channels x time x trials]
disp('Trial segmentation...')
[active_data, rest_data, traces] = treat_segment_trials(av_processed_signal, event_vector_ds,sfreq,trialLength);


%%% Regression: correlate HFB activity with task labels
fprintf('Correlating %s activity with task labels...\n',lower(feat_oi))

[R2_stats, ~, ~] = treat_regress_hfb_to_task(active_data, rest_data);

figure('Name','Task Regression: signed R^2','Color','w');
bar(R2_stats(:,1), 'FaceColor', [0.4 0.6 0.8]); hold on;
%p values < 0.05 (not bonferonni corrected!) 
sig_idx = find(R2_stats(:,2) < 0.05);

peakSign = userInputs.peakSign;
switch peakSign
    case 'positive'
        signed_idx = find((R2_stats(:,1)>0));
        signed_sig_idx = intersect(sig_idx,signed_idx);
        plot(signed_sig_idx, R2_stats(signed_sig_idx,1)+0.02, '*r', 'MarkerSize', 8);
    case 'negative'
        signed_idx = find((R2_stats(:,1)<0));
        signed_sig_idx = intersect(sig_idx,signed_idx);
        plot(signed_sig_idx, R2_stats(signed_sig_idx,1)-0.02, '*r', 'MarkerSize', 8);
end

hold off;
xlabel('Channel'); ylabel('Signed R^2');
title('Task Regression (signed R^2, *p<0.05)');
subtitle('Marked channels are included in further analysis')
grid on; box off;

%%% Preparing TREAT
[num_samples,num_trials] = size(traces,[2 3]);

%check: number of channels to average over should be larger than 1 
if length(signed_sig_idx) < 2
    error('%d significancly respoding channel(s) identified with %s sign, which is too little for TREAT to work well...', length(signed_sig_idx),peakSign)
end

%1. obtain the average HFB signal, averaged over the channels you're interested in.
sel_traces = squeeze(traces(signed_sig_idx,:,:));
num_channels = size(sel_traces,1);

%smooth over 0.2 sec
% trials_oi_smooth =zeros(num_trials,num_samples,n_best);
trials_oi_smooth =zeros(num_trials,num_samples,num_channels);

for i = 1:num_trials %for each trial
    for j = 1:num_channels %for each channel
        to_smooth =    sel_traces(j,:,i);
        trials_oi_smooth(i,:,j) = smooth(to_smooth,sfreq/5);
    end
end

%average over channels
mean_trace = mean(trials_oi_smooth,3);
mean_trace_not_smoothed =  squeeze(mean(sel_traces,1))';

%timepoint per sample, in seconds
time_per_trial        = -trialLength+(1/sfreq):(1/sfreq):trialLength;

%Define the moment where your trial the cue appears, so that the
%appropriate time windows can be computed. Currently the code is set up so
%that cue_moment == trialLength. 
cue_moment = trialLength; 

% 1. Trial selection.
%this is where the real work starts.
disp('Trial selection...')

%if you're interested in the negative peaks, flip the signal; the following
%functions only work with positive values. (The plots will be of the
%origingal signal) 
if strcmp(peakSign,'positive')
    trace_oi = mean_trace;
elseif strcmp(peakSign,'negative')
    trace_oi = -mean_trace;
end
[selected_trials, slope_guess] = treat_trial_selection_20260130(trace_oi,cue_moment,sfreq,userInputs);

figure('units','normalized','outerposition',[0 0 1 1]); hold on;
for i = 1:size(mean_trace,1)
    % ax(i) = subplot(ceil(sqrt(num_trials)),ceil(sqrt(num_trials)),i); 
    subplot(ceil(sqrt(size(mean_trace,1))),ceil(sqrt(size(mean_trace,1))),i)
    hold on;
    plot(time_per_trial,mean_trace(i,:))
    
    if selected_trials(i)
        title(sprintf('trial %d',i))
    else
        title(sprintf('trial %d',i),'Color','r')
    end
    xline(0,':')
    xlim tight
end
%link axes, if you want to.
% linkaxes(ax, 'xy')

treat_make_pretty
sgtitle(sprintf('Average signal over %d electrodes with significant R^2 values',num_channels))

% 2. set time window and display time window for neural slope marker.
%This is something you'll have to play with to get sensible results.
[startTime, endTime] = treat_neuralSlopeGUI(trialLength);

tw = [cue_moment+startTime cue_moment+endTime]; %in seconds. add the cue time to more easy calculate the NSM later. 

% 3. Define the time interval (th=epsilon_ni, in seconds) around the line segment
% with which you calculate the distance between slope and signal.
% th 0.5 is a good starting point.
th = 0.5;

% 4. load or define the optimal slope of the line segment, and plot.
% You can calculate the slope for each new dataset, irrespective of the subject (default) 
% or, you can follow Branco et al., 2017, who states that the slope is ubject specific and thus should be the same for all
% movements of a particular subject (see Branco et al., 2017).
new_slope = 1; 

if new_slope %use the slope that is calculated from the current data
        opt_m = slope_guess;
        disp('Calculating the slope from the current data...')
else %or: use the slope that was previously defined for this subject 

    cd([userInputs.treatFolder '/data']) %#ok<UNRCH>
    fileInfo = dir(sprintf('%s_opt_m.mat',subj));
    fprintf('Searching for a previously saved slope value for %s...\n',subj)
    %run slope optimization, if you wish.
    if isempty(fileInfo)
        disp('No file found, calculating the slope from the current data...')

        % opt_m = treat_find_optimal_slope(mean_trace,time_per_trial,tw,disp_tw,th,selected_trials,slope_guess);
        opt_m = slope_guess;
        save(sprintf('%s_opt_m.mat',subj),'opt_m')
        disp('Saving for potential future use...')
    end

    load(sprintf('%s_opt_m.mat',subj))
end

% The second part of the method is to match the neural traces to a slope:
%Match a straight line with fixed slope and increasing b from tw(1) to tw(2).
%Extract the value point of best regression between the curves and repeat
%for each trial (averaged over significant channels).

% 5. Exctract the neural slope marker
disp('Extracting neural slope marker...')
[nSlopemarker,~] = treat_extract_NSM_20260130(trace_oi,sfreq,time_per_trial,tw,opt_m,th,selected_trials,cue_moment,userInputs);

% 6. Realign the trials using the neural slope markers:
%allocate
shiftedtrials = nan(num_trials,size(time_per_trial,2));

good_trial_no = find(selected_trials);

first_good_trial = good_trial_no(1);
mean_av_processed_signal = mean(av_processed_signal(:,signed_sig_idx),2);

rel_cueTimes_ds = find(event_vector_ds==1); %find the cuetimes of the relevant codes
samples_per_trial = round(time_per_trial*sfreq); 

cueTime_oi = rel_cueTimes_ds(first_good_trial); %the cuetime of the first good trial
ref_trial = mean_av_processed_signal(samples_per_trial + cueTime_oi); %take the trial around that cue from the averaged signal

%created a cell with aligned trials
shiftedtrials(1,:) = ref_trial;
pos                   = find(round(time_per_trial,4)==round(nSlopemarker{1}(first_good_trial),4)); %find where in time (s) this NSM occurs. round because of very small difference that may occur

%plot first good trial:
figure('units','normalized','outerposition',[0 0 1 1])

subplot(ceil(sqrt(sum(selected_trials))),ceil(sqrt(sum(selected_trials))),1); hold on;

plot(time_per_trial,ref_trial, ...
    nSlopemarker{1}(first_good_trial),ref_trial(pos),'*r');
title(sprintf('Trial %d (reference)',first_good_trial))
axis square
axis tight
%align all trials to the first good trial:

%counter for the subplot index.
yy = 1;
for tr= good_trial_no(2:end)
    yy = yy + 1;

    %fi=mean_trace_not_smoothed(tr,:);
    cueTime_oi = rel_cueTimes_ds(tr); %the cuetime of the current trial

    %calculate distance between markers:
    bi                     = nSlopemarker{1}(tr);

    posi = find(round(bi, 4) == round(time_per_trial, 4)); %find where in time (s) this NSM occurs. round because of very small difference that may occur
    d                      = posi-pos;

    shiftedtrials(tr,:) = mean_av_processed_signal(samples_per_trial + cueTime_oi + d);

    %plot overlap between first trial and all other trials
    subplot(ceil(sqrt(sum(selected_trials))),ceil(sqrt(sum(selected_trials))),yy); hold on;
    plot(time_per_trial,ref_trial,time_per_trial,shiftedtrials(tr,:));

    axis square
    xlim tight
    title(sprintf('trial %d',tr))
    xline(0,':')
end

% sgtitle(sprintf('%s, run %d - trial alignment',gesture,run_oi))
sgtitle('Trial alignment')

figure('units','normalized','outerposition',[0 0 1 1]);hold on;
ax2(1) = subplot(1,3,1); hold on;
title('Not aligned, all trials')
xline(0,':')
plot(time_per_trial,mean(mean_trace_not_smoothed,1),'k','LineWidth',2)
plot(time_per_trial,mean(mean_trace_not_smoothed,1)+std(mean_trace_not_smoothed,[],1),'k--','HandleVisibility','off')
plot(time_per_trial,mean(mean_trace_not_smoothed,1)-std(mean_trace_not_smoothed,[],1),'k--','HandleVisibility','off')
grid on;

ax2(2) = subplot(1,3,2);hold on;
title('Not aligned, bad trials excluded')
xline(0,':')
plot(time_per_trial,mean(mean_trace_not_smoothed(selected_trials,:),1),'b','LineWidth',2)
plot(time_per_trial,mean(mean_trace_not_smoothed(selected_trials,:),1)+std(mean_trace_not_smoothed(selected_trials,:),[],1),'b--','HandleVisibility','off')
plot(time_per_trial,mean(mean_trace_not_smoothed(selected_trials,:),1)-std(mean_trace_not_smoothed(selected_trials,:),[],1),'b--','HandleVisibility','off')
grid on;

ax2(3) = subplot(1,3,3);hold on;
title(sprintf('Aligned to trial %d, the first good trial, bad trials excluded',first_good_trial));
xline(0,':')
plot(time_per_trial,nanmean(shiftedtrials,1),'r','LineWidth',2) %#ok<*NANMEAN>
plot(time_per_trial,nanmean(shiftedtrials,1)+nanstd(shiftedtrials,[],1),'r--','HandleVisibility','off') %#ok<*NANSTD>
plot(time_per_trial,nanmean(shiftedtrials,1)-nanstd(shiftedtrials,[],1),'r--','HandleVisibility','off')
grid on;
linkaxes(ax2,'xy')
% sgtitle(sprintf('%s, run %d - mean over trials',gesture,run_oi))
sgtitle('Mean over trials')

treat_make_pretty
 
%save  magnitude and index of the peaks of the averages across trials to quantify effects later
[m_or,i_or] = max(mean(mean_trace_not_smoothed,1)); %original trials
[m_gt,i_gt] = max(mean(mean_trace_not_smoothed(selected_trials,:),1)); %selected trials
[m_sh,i_sh] = max(nanmean(shiftedtrials,1)); %shifted trials

peaks_all.orig = m_or;
peaks_all.good_chan = m_gt;
peaks_all.shifted = m_sh;

min_all.orig = min(mean(mean_trace_not_smoothed(:,1:i_or),1));
min_all.good_chan = min(mean(mean_trace_not_smoothed(selected_trials,1:i_gt),1));
min_all.shifted = min(nanmean(shiftedtrials(:,1:i_sh,1)));

if userInputs.saveNSM
    disp('Saving neural slope markers in the current directory...')

    save(sprintf('%s_neuralSlopemarker.mat',userInputs.subjectName), 'nSlopemarker','-mat');
end
end