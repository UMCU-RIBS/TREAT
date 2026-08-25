function [data,codes,startTimes,srate] = treat_load_dat(filename)
% This file is part of the TREAT Toolbox V1.0
% Copyright © 2026 University Medical Center Utrecht 
% Main Authors: Mariana P Branco, Simon Geukes

%load bci2000 file
[data, states, parameters] = load_bcidat(filename,'-calibrated'); %in uV

if isfield(states,'MicromedCode') %if micromed data
    disp('Loading Micromed .dat file...')
    allevent = double(states.MicromedCode); 

elseif isfield(states,'StimulusCode') 
    disp('Loading .dat file...')
    allevent = double(states.StimulusCode);

else
    error('Events are absent or stored in an unfamiliar way. Please double check your data and/or adjust this loading function...')
end

if isfield(states,'MicromedCodeSampleNr')
    codes  = allevent(double(states.MicromedCodeSampleNr)~=0);
    startTimes = find(states.MicromedCodeSampleNr~=0);
else
    codes  = allevent(find(diff([0; allevent])~=0)); %#ok<FNDSB>
    startTimes = find(diff([0; allevent])~=0);
end

%get dims in correct order for output 
if size(data,1)>size(data,2)
    data = data'; %output should be [channel x time]
end
srate = parameters.SamplingRate.NumericValue;


end