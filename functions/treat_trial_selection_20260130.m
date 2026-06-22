function [selected_trials, slope_guess] = treat_trial_selection_20260130(mean_trace,cue_moment,sfreq,userInputs)
trialPercentage = userInputs.trialPercentage;

%number of trials
num_trials = size(mean_trace,1); 

%setting time periods of interest for the active and rest
%periods for trial selection, in seconds.
act_ind = [cue_moment+0.3 cue_moment+1.5]; %2026-02-11: extended from 1.0 to 1.5 seconds to accomodate slower responses. 
rest_ind = [cue_moment-1.5 cue_moment-0.3];

fprintf(['The active period for trial selection is defined as %.2f - %.2fs... \n' ...
    'The rest period for trial selection is defined as %.2f - %.2fs...\n'],...
    act_ind(1),act_ind(2),rest_ind(1),rest_ind(2))

act_sig = mean_trace(:,(act_ind(1)*sfreq)+1:(act_ind(2)*sfreq))';
rest_sig = mean_trace(:,(rest_ind(1)*sfreq)+1:(rest_ind(2)*sfreq))';

%find the peak in the signal of interest
[peak_max,peak_ind] = max(act_sig);

%exclude trials where the index of the peak is 1. That means that the
%signal is only going down; it won't be possible to fit a postive slope
%to these trials. 
peak_one = peak_ind == 1; 
%peak_one = false(1,num_trials); %check later

%find the minimum value in the period up to the index of the peak (so that
%the minimum always falls before that. We want to see a signal that goes
%up in response to the cue, not down.
for i = 1:num_trials
    [peak_min(i),min_ind(i)] = min(act_sig((1:peak_ind(i)),i));
end

%first guess for optimal slope. %CAREFUL! includes all trials. should only
%be selected trials. 
slope_guess = mean((peak_max(~peak_one)-peak_min(~peak_one))./((peak_ind(~peak_one)-min_ind(~peak_one))/sfreq));

%Run trial selection, if you want
if ~userInputs.trialSelection

    selected_trials = ~peak_one;

    if sum(peak_one)>0
        fprintf('Excluded %d of the %d trials (%.1f%%), we cannot fit a slope without a peak in the trial...\n', ...
            sum(peak_one),num_trials, sum(peak_one)/num_trials*100)
    end

elseif userInputs.trialSelection %#ok<*UNRCH>

    %allocate
    selected_trials = false(1,num_trials);

    %get the ratio between delta y and the std of the rest period
    peak_rat = (peak_max-peak_min)./std(rest_sig);

    %sort by ratio, high to low.
    [~,I2] = sort(peak_rat,'descend');

    %determine the number of selected trials, based on the percentage of
    %trials you want to include
    num_sel_trials = round(num_trials*(trialPercentage/100));

    %select those, sorted by the ratio
    selected_trials(I2(1:num_sel_trials)) = true;

    if any(peak_rat(selected_trials) == 0)
        error(['There are trials without a peak in the selected trials. ' ...
            'Check your trials, you should probably exclude more than %d%%...'],trialPercentage)
    end

    %plot trial selection
    figure;hold on;
    xtr = 1:num_trials;
    plot(xtr(selected_trials),peak_rat(selected_trials),'bx','LineWidth',2);
    plot(xtr(~selected_trials),peak_rat(~selected_trials),'rx','LineWidth',2);
    legend('Included trials','Excluded trials')
    % yline(cutoff,'r--','LineWidth',2);
    xlabel('Trial #')
    ylabel('Ratio')
    ylim([0 inf])
    title('Trial selection',...
        '\DeltaY divided by the standard deviation of rest period')
    xlim tight
    treat_make_pretty
end

end
