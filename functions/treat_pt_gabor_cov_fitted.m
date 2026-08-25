% % This file is part of the TREAT Toolbox V1.0
% Copyright © 2026 University Medical Center Utrecht 
% Main Authors: Mariana P Branco, Simon Geukes
% This function is a copy of the gabor wavelet function written by 
% Zachary Freudenburg 
% 
% *** the gabor wavelet vector size is fitted to the wavelet width to speed
% up convoultion at high frequencies
%
% *** signal is subsampled to speed up convolution at low frequencies...
%
%  Input:  X is a N x T matrix that has N rows of length T time varing signals.
%          F is list of M frequency values of the spectrum
%          sample_f is the frequency at which the analogy signal was sample
%                   to create the discrete rows of X
%          span is the span in wavelegths of the gabor wavelet (numer of wavelegths of the wavelet that are significantly > 0)
%
%  Output: S is the MxT gabor convoultion spectrum
%
%  Example Usage:
%     X = rand(1000,1);
%     F = 10;   % can also be a list of frequencies F = [1:10 100:200];
%     span = 3; % 3 wavelengths per wavelet
%     S = gabor(X,f,1200,span);
%
%  PT (C), Zac Freudenburg, 2008.

%% returns the convolution of x with a gabor filter of frequency fs and
%% a width of ~ 5 periods

function gabor_return = treat_pt_gabor_cov_fitted(X,params,type,dim,verbose)
% args --> X, parms, type, dim
%        > type can be 'amp'(real part),'log_amp','amp_norm','phase'(imaginary),or''==complex
%        > dim is dimension of time for returned spectra dim=1->time 1st
%             else time is last

if (nargin<=2) type = ''; end
if (nargin<=3) dim = 3; end
if (nargin<5) verbose = 0; end

F = params.spectra;
sample_f = params.sample_rate;
span = params.W;
buffer_size = 0; 
unbuffered_start = buffer_size+1;

unbuffered_stop = size(X,2)-buffer_size-1;


[sizeX] = size(X);
if (dim==1)
    gabor = single(zeros(size(X,2)-2*buffer_size,size(X,1),size(F,2)));
else
    gabor = single(zeros(size(X,1),size(F,2),size(X,2)-2*buffer_size));
end

numFreqs = size(F,2);



if verbose; f_cnt=1; tt=tic; end;
for next_f=numFreqs:-1:1
    fs=F(next_f);
    
    if verbose; disp(['starting Gabor frequency ',num2str(fs),' (',num2str(f_cnt),'of',num2str(numFreqs),') ...']); t1 = tic; end;
    
    t = -(4*span/fs)+(rem(4*span/fs,1/sample_f)):(1/sample_f):(4*span/fs)-(rem(4*span/fs,1/sample_f));
    thisPeriod = 1/fs;
    sigma_t = span*thisPeriod;
    
    gauss = exp(-t.^2./2./sigma_t^2)./(sqrt(2*pi)*sigma_t);
    s = cos(2*pi*fs*t) + 1i * sin(2*pi*fs*t);    % sin/cos spiral in complex space of frequency 'fs'
    gab = gauss.*s;
    
    size_gab=length(gab);
    working_X=X; 
    size_working_X=size(working_X);
    
    if 0 
        gab=imresize(gab,[1 1201],'bilinear');
        resize_factor=(length(gab)/size_gab)*size(working_X,2);
        working_X=imresize(working_X,[size(X,1) resize_factor],'bilinear');
        gabor_response_ds = conv2(working_X,gab,'same');
        gabor_response = imresize(gabor_response_ds,size_working_X,'bilinear');
        
    else
        gabor_response = conv2(working_X,gab,'same');
    end
    
    if (dim==1)
        gabor(:,:,next_f) = gabor_response';
    else
        gabor(:,next_f,:) = gabor_response;
    end
    
    if verbose; disp(['   ... done (time ',num2str(toc(t1)),') ...']); t1 = tic; f_cnt=f_cnt+1; end;
end %next_f


switch type
    case 'amp' %amp
        gabor_return = abs(gabor);
        
    case 'log_amp' %amp
        temp_gabor = abs(gabor);
        temp_gabor(temp_gabor<0.1) = 0.1; %Threshold log spect to avoid large neg numbers in log
        gabor_return = log(temp_gabor);
        
    case 'amp_norm' %amp
        if (dim==1)
            gabor_return = (abs(gabor)./repmat(mean(abs(gabor)),[size(gabor,1) 1 1]));
        else
            gabor_return = (abs(gabor)./repmat(mean(abs(gabor)),[1 1 size(gabor,3)]));
        end
        
    case 'phase' %phase
        gabor_return = angle(gabor);
        
    otherwise %imaginary
        gabor_return = gabor;
end

if verbose; disp([' *** total Gabor time = ',num2str(toc(tt))]); end;
