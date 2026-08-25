function [lmp_data,events_adj] = treat_calculate_LMP(data,windowsize,sfreq,events)
% This file is part of the TREAT Toolbox V1.0
% Copyright © 2026 University Medical Center Utrecht 
% Main Authors: Mariana P Branco, Simon Geukes

windowsize_samples = round(windowsize*sfreq); % convert to samples
lmp_data = movmean(data,[windowsize_samples,0], 2, 'Endpoints', 'fill'); %"fill":	Replace nonexisting elements with NaN.

% remove all columns with all NaNs
lmp_data = lmp_data(:, ~all(isnan(lmp_data),1)); 

lmp_data = lmp_data'; %flip dimension to [time x channels]

% adjust events; all events now occur earlier, because the
% first samples have been removed in the data. 
events_adj = zeros(1,size(events,2));
rel_samp = find(events == 1); 
adj_samp = rel_samp - windowsize_samples;
events_adj(adj_samp) = 1;


end