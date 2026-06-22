function [R2_stats, rest_feature_means, act_feature_means] = treat_regress_hfb_to_task(active_data, rest_data)
% Compute signed r^2 and p-values for each channel using corrcoef
    num_chan = size(active_data,1);
    act_feature_means = squeeze(mean(active_data,2))'; % [trials x channels]
    rest_feature_means = squeeze(mean(rest_data,2))';  % [trials x channels]

    R2_stats = zeros(num_chan,2);
    for ch = 1:num_chan %for each channel
        x = [rest_feature_means(:,ch); act_feature_means(:,ch)];
        y = [zeros(size(rest_feature_means,1),1); ones(size(act_feature_means,1),1)];
        [R,P] = corrcoef(x,y);
        r = R(1,2); %r value: correlation coefficient
        p = P(1,2); %p statistic
        R2_stats(ch,:) = [sign(r)*r^2, p]; %square R value to get R^2
    end
end
