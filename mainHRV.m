clc;
clear all;
%%
%%%%%%%%%%%%%%%%CONVERT PHYSIONET FILE TO CSV%%%%%%%%%%%%%%%%%%%

filename = '100'; % without extension
hea = fileread([filename '.hea']);
lines = splitlines(hea);
mainLine = strtrim(lines{1});
parts = split(mainLine);
recordName = parts{1};
numSignals = str2double(parts{2});
fs = str2double(parts{3}); % sampling frequency
numSamples = str2double(parts{4}); % number of samples

disp(['Sampling rate: ' num2str(fs) ' Hz, Channels: ' num2str(numSignals)]);

fid = fopen([filename '.dat'], 'r');
data = fread(fid, 'uint8');
fclose(fid);

M = floor(length(data)/3);
signal = zeros(M, 2);

for i = 1:M
    byte1 = data(3*i - 2);
    byte2 = data(3*i - 1);
    byte3 = data(3*i);

    sig1 = bitand(byte1, 255) + bitshift(bitand(byte2, 15), 8);
    if sig1 >= 2048, sig1 = sig1 - 4096; end

    sig2 = bitshift(bitand(byte2, 240), -4) + bitshift(byte3, 4);
    if sig2 >= 2048, sig2 = sig2 - 4096; end

    signal(i, :) = [sig1 sig2];
end

t = (0:M-1)' / fs;

fid = fopen([filename '_signal.csv'], 'w');

for i = 1:M
    t_str = strrep(sprintf('%.6f', t(i)), '.', ',');  % Replace . with ,
    fprintf(fid, '%s;%.0f;%.0f\n', t_str, signal(i,1), signal(i,2));
end

fclose(fid);
disp('Signal CSV written successfully!');


%% %%%%%%%% SIGNAL UPLOAD %%%%%%%%%
data = readmatrix('100_signalv2.csv'); 

%weird numbers cuz rest of it, have weird amplitudes, so didnt bother
%cleaning them just cut this shit up
t = data(1:1400*360, 1);        % time[s]
ecg = data(1:1400*360, 2);      % ECG[mV]

% estimate sampling frequency
fs = 1 / mean(diff(t));  
fprintf('Estimated sampling rate: %.2f Hz\n', fs);


%% %%%%%%%% FILTERING AND R-R PEAKS DETECTION %%%%%%%%%
% filter
ecgFilt = bandpass(ecg, [0.5 40], fs);  

% weird shit at the beginning and the end, so just cut this shit out
margin = round(fs * 1);
ecgTrimmed = ecgFilt(margin:end-margin);
tTrimmed = t(margin:end-margin);

% detect r peaks
[~, rLocsRel] = findpeaks(ecgTrimmed, 'MinPeakHeight', 0.6 * max(ecgTrimmed), ...
    'MinPeakDistance', round(0.3 * fs));

plot(tTrimmed, ecgTrimmed); hold on;
plot(tTrimmed(rLocsRel), ecgTrimmed(rLocsRel), 'r*'); 
title('Trimmed ECG with R-peaks');


%% %%%%%%% COMPUTE RR SIGNAL (HRV SIGNAL) %%%%%%%
rrIntervals = diff(t(rLocsRel));      % RR interval[s]
rrTimes = t(rLocsRel(2:end));         % t[s]

% plot HRV(t)
figure;
plot(rrTimes, rrIntervals * 1000); % HRV in ms
xlabel('Time (s)'); ylabel('RR Interval (ms)'); title('HRV(t)');


%% %%%%%%%% TIME DOMAIN ANALYSIS %%%%%%%%%
meanRR = mean(rrIntervals);
stdRR = std(rrIntervals);
RMSSD = sqrt(mean(diff(rrIntervals).^2));
NN50 = sum(abs(diff(rrIntervals)) > 0.05);
pNN50 = 100 * NN50 / length(rrIntervals);

fprintf('\nTime-Domain HRV Indices:\n');
fprintf('Mean RR: %.3f s\nSTD RR: %.3f s\nRMSSD: %.3f s\npNN50: %.2f%%\n', ...
    meanRR, stdRR, RMSSD, pNN50);

% meanRR - mean time between each RR in signal
% stdRR - standard deviation of RR signal (how much the signal fluctuate)
% RMSSD - root mean square of successive differences (how much each
% heart beat differs from the next one
% NN50 - number of successive RR interval differences (counts how many
% times RR intervals differ by more than 50ms)
% pNN50 - percentage of NN50 over all intervals

% whoever was tested, buddy, me smoking and drinking energy drinks, my
% heart is healthy as a horse compared to them 💀


%% %%%%%%%% FREQUENCY DOMAIN %%%%%%%%%%
% interpolate to uniform base (frequency analysis methods (like Welch)
% expect evenly sampled data)
fsInterp = 4;                                                   % interpolation frequency [Hz]
tUniform = rrTimes(1):1/fsInterp:rrTimes(end);                  % uniform time base
rrInterp = interp1(rrTimes, rrIntervals, tUniform, 'spline');   % interpolated rr peaks

% Detrend signal (removes slow, non-oscillatory trends (like a slow drift
% in HR baseline)), focus only on oscillations (variability), not long-term trends
rrDetrend = detrend(rrInterp);

% Compute PSD (Power Spectral Density) using Welch, to check how power is 
% distributed across frequency bands, uses windowed FFT averaging → more
% stable and smooth PSD.
% PSD reveals which frequency bands carry how much HRV "power"
[pxx, f] = pwelch(rrDetrend, [], [], [], fsInterp);

% Band powers:
% LF	0.04–0.15	Low-Frequency: Mix of sympathetic + parasympathetic
% HF	0.15–0.4	High-Frequency: Mainly parasympathetic (vagal)
% LF/HF	        	Balance between sympathetic/parasympathetic
% (sympathovagal balance)
% High HF → relaxed, good vagal tone
% High LF/HF → stress, sympathetic dominance.
LF  = bandpower(pxx, f, [0.04 0.15], 'psd');
HF  = bandpower(pxx, f, [0.15 0.4], 'psd');
LF_HF = LF / HF;

fprintf('\nFrequency-Domain HRV Indices:\n');
fprintf('LF Power: %.3f\nHF Power: %.3f\nLF/HF Ratio: %.3f\n', LF, HF, LF_HF);

% plot that bitch
figure;
plot(f, pxx);
xlim([0 0.5]);
xlabel('Frequency (Hz)'); ylabel('PSD');
title('HRV Frequency Spectrum');