function [data,codes,startTimes,srate] = treat_load_trc_m2025b(filename)
% This file is part of the TREAT Toolbox V1.0
% Copyright © 2026 University Medical Center Utrecht 
% Main Authors: Mariana P Branco, Simon Geukes

% load the data
SETTINGS.loadevents.state = 'yes';
SETTINGS.loadevents.type = 'analog';
SETTINGS.loadevents.dig_ch1='';
SETTINGS.loadevents.dig_ch1_label='';
SETTINGS.loadevents.dig_ch2='';
SETTINGS.loadevents.dig_ch2_label='';
SETTINGS.chan_adjust_status=0;
SETTINGS.chan_exclude_status=0;
SETTINGS.chan_adjust='';
SETTINGS.chan_exclude='';
SETTINGS.chans=[];
SETTINGS.filename = filename;
SETTINGS.verbose = 'yes';
SETTINGS.loaddata.state = 'yes';
SETTINGS.loaddata.type = 'uV';
SETTINGS.movenonEEGchannels = 'yes';

[trc, data, ~] = jun_readtrc( SETTINGS );

% Convert the events into a condition vector.
conditionVector = zeros(1,trc.pnts);

startTimes = [trc.event.latency];
codes = [trc.event.value];
srate = trc.srate; 

for event = 1 : length(startTimes)
    if event < length(startTimes)
        conditionVector( startTimes(event) : startTimes(event+1) ) = codes(event);
    elseif event == length(startTimes)
        conditionVector( startTimes(event) : trc.pnts ) = codes(event);
    end
end

% Store the conditions in a 'states' structure.
% states.MicromedCode			= conditionVector';


end