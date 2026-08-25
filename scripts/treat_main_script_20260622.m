% This file is part of the TREAT Toolbox V1.0
% Copyright © 2026 University Medical Center Utrecht 
% Main Authors: Mariana P Branco, Simon Geukes

% Main script to run the TREAT toolbox
clc; clear except; close all;

%adjust this path so that it points to your own version of treat, e.g.: 
treatFolder = '/home/simon/Documents/MATLAB/Toolboxes/TREAT/TREAT/'; 

addpath(genpath(treatFolder)) 

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
nSlopemarker = run_treat_20260622(data, codes,startTimes, samplingRate,userInputs);


