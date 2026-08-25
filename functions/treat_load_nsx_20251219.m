function [data,codes,startTimes,srate] = treat_load_nsx_20251219(filename)
% This file is part of the TREAT Toolbox V1.0
% Copyright © 2026 University Medical Center Utrecht 
% Main Authors: Mariana P Branco, Simon Geukes

%loading nsx and nev files using the nsx file name. 

filepath = filename(1:end-4);
disp('Loading .nev file...')
nev      = openNEV( [filepath '.nev'], 'nomat', 'nosave' );

disp('Loading .nsx file...')
nsx      = openNSx( filename, 'uv');
srate = nsx.MetaTags.SamplingFreq;
data = nsx.Data; %data should be a double.

%get dims in correct order for output 
if size(data,1)>size(data,2)
    data = data'; %output should be [channel x time]
end

%  update to the loading function following
%  firmware update in 2024, release note here:
%  https://support.blackrockneurotech.com/portal/en/kb/articles/ptp-alignment
try
    startTimesSec = ((double(nev.Data.SerialDigitalIO.TimeStamp)-nsx.MetaTags.Timestamp)/nsx.MetaTags.TimeRes)';
    startTimes = round(startTimesSec * srate);
    codes = double(nev.Data.SerialDigitalIO.UnparsedData);
catch
    disp('Reading BR data the new way did not work, reverting to the old way...')
    % older ways to load; needed for some of the older recordings
    startTimes	= round( (nev.Data.SerialDigitalIO.TimeStampSec * srate) );
    codes		= double( nev.Data.SerialDigitalIO.UnparsedData )';
end

end