function [nSlopemarker,min_dists] = treat_extract_NSM_20260130(power_data,sfreq,time_per_trial,tw,m,th,good_trials,cue_moment,userInputs)
% This file is part of the TREAT Toolbox V1.0
% Copyright © 2026 University Medical Center Utrecht 
% Main Authors: Mariana P Branco, Simon Geukes

figs = 1; %flag for figures

tw_samp = tw * sfreq; %time window in samples

%have the time per trial start from 0 to make calculation of the NSM a
%little easier. 
time_per_trial_ref = time_per_trial + cue_moment;  

if figs
    figure('Name','Neural Slope Markers','NumberTitle','off', ...
        'units','normalized','outerposition',[0 0 1 1])
end

bval_tr = [];
alldist_tr = []; 

for tr=1:size(power_data,1)

    %Select trial
    trial_oi = power_data(tr,:);

    [yval, I, ~] = unique(trial_oi(tw_samp(1):tw_samp(2))); 

    %find middle value of the signal (mean between min and max of the tw the user selected)
    ymax = max(trial_oi(tw_samp(1):tw_samp(2)));
    ymin = min(trial_oi(tw_samp(1):tw_samp(2)));
    ymean = mean([ymax ymin]);

    line_middle = ymean/m;

    % define b as running from zero and ending at the length of the time
    % window.
    bval = 0:.001:(tw(2)-tw(1));

    %remove the distance between the offset and middle of the line,
    %so that b0 starts at the beginning of the time window, and ends at the end of the time window.
    bval = bval - line_middle;
    bval_tr(tr,:) = bval; %save for plot later

    %Calculate the distance between slope and signal:
    alldist = [];

    %for each b value: all time points in the trial.
    for b=bval

        %define time points of the line segment:
        %divide the y-valeus by the slope and add the current offset, b
        xval = (yval/m + b);

        %calculate the distance between  each time point of the line (xval),
        % and the time point corresponding to each unique yvalue in the signal (time_per_trial_ref(I)).
        dist = abs(xval-time_per_trial_ref(I));

        %for each point on the line, check if the corresponding
        %distance is larger than the th. If so, set the distance
        %value to 0.
        th_cross_count = 0;
        for k=1:size(dist,2)
            if dist(k)>th
                th_cross_count = th_cross_count + 1;
                dist(k) = 0;
            end
        end

        %sum all distances, and divide by the number of points on the
        %line where the distance did not cross the th.
        alldist = [alldist, sum(dist)./length(find(dist~=0))];
    end

    alldist_tr(tr,:) = alldist; %save for plot later

    %Extract the minimum val of b, i.e. the point of minimal distance
    % between the line and the signal:
    [minval, minind] = min(alldist);
    min_dists{1}(tr) = minval;

    %redefine the xvalues: the line with the best offset, and add the
    %the start of the time window for correct plotting later.
    xval = yval/m + (bval(minind)+tw(1));

    %newbval is the neural slope marker, meaning: B0 + the middle point of the slope
    newbval = line_middle + (bval(minind)+tw(1));

    %Collect the closest values in xval so that it has a match with  a
    %time point
    xdiff = time_per_trial_ref-newbval;
    [~, xind] = min(abs(xdiff));
    newbval = time_per_trial_ref(xind);

    %add NSM to cell. If it was not part of the selected trials, save a
    %nan.
    if good_trials(tr)
        nSlopemarker{1}(tr) = newbval;
    else
        nSlopemarker{1}(tr) = nan;
    end

    if figs
        trial_oi = power_data(tr,:);

        subplot(ceil(sqrt(size(power_data,1))),ceil(sqrt(size(power_data,1))),tr),

        % xlim([disp_tw(1),disp_tw(2)])
        if strcmp(userInputs.peakSign,'positive')
            plot(time_per_trial_ref,trial_oi); hold on;
            plot(xval,yval,'.k',nSlopemarker{1}(tr),ymean,'*r'); hold off;
        else %in case of negative, flip slope and ymean so that everthing comes to its original form
            plot(time_per_trial_ref,-trial_oi); hold on;
            plot(xval,-yval,'.k',nSlopemarker{1}(tr),-ymean,'*r'); hold off;
        end
        xline( cue_moment, 'k:')
        sgtitle('Neural Slope Markers');
        set(gca,'XTick',[0  time_per_trial(end)  time_per_trial(end) *2], ...
            'XTickLabel',[-time_per_trial(end) 0 time_per_trial(end)])
        axis square;

        if good_trials(tr)
            title(sprintf('trial %d',tr))
        else
            title(sprintf('trial %d',tr),"Color",'r')
        end
        treat_make_pretty
    end
    if good_trials(tr)
        nSlopemarker{1}(tr) = nSlopemarker{1}(tr)  - cue_moment; % for easier use: save NSM relative to the cue (rather than the start of trial)
    end
end
%make some plots, if you want to.
figure('Name','Min. Dist.','NumberTitle','off', ...
    'units','normalized','outerposition',[0 0 1 1])
for tr=1:size(power_data,1)
    subplot(ceil(sqrt(size(power_data,1))),ceil(sqrt(size(power_data,1))),tr); hold on;

    plot(bval_tr(tr,:),alldist_tr(tr,:));
    [~,minind_d] = min(alldist_tr(tr,:));

    plot(bval_tr(tr,minind_d),alldist_tr(tr,minind_d), '*r','MarkerSize',8, 'LineWidth',2); hold off;
    if good_trials(tr)
        title(sprintf('trial %d',tr))
    else
        title(sprintf('trial %d',tr),"Color",'r')
    end
    set(gca,'XTick',[bval_tr(tr,1),bval_tr(tr,end)],'Xticklabel',[tw(1)-cue_moment,tw(2)-cue_moment])
    sgtitle('Control figure: Distance between slope and signal (xlabel: start of the line, b0, in seconds)');
    axis tight
    axis square
    % xlabel('b0')
end
treat_make_pretty




end

