clc; clear except; close all;

%adjust this path so that it points to your own version of treat, e.g.: 
treatFolder = '/home/simon/Documents/MATLAB/TREAT/'; 

addpath(genpath(treatFolder)) 

%paths to loading functions
addpath(genpath('/usr/local/matlabtools_LATEST/NPMK'));
addpath('/usr/local/matlabtools_LATEST/readtrc/');
addpath('/usr/local/matlabtools_LATEST/BCI_2000/');

%get user inputs 
userInputs = treat_getUserInputsGUI_20260622(treatFolder);

%load data depending on file type
switch userInputs.fileType
    case 'trc'
        [data,codes,startTimes,samplingRate] = treat_load_trc_m2025b(userInputs.FilePath);
    case 'dat'
        [data,codes,startTimes,samplingRate] = treat_load_dat(userInputs.FilePath);
    case 'nsx'
        [data,codes,startTimes,samplingRate] = treat_load_nsx_20251219(userInputs.FilePath);
    case 'bids'
        disp('Working on it!')
end

%% run treat
[nSlopemarker,peaks_all,min_all] = run_treat_20260622(data, codes,startTimes, samplingRate,userInputs);


