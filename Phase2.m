close all;
clc;

% Modulation Technique 1: On-Off Keying 

%{ 
    - Num of bits = 1024 (given)
    - Let the carrier frequency be 10KHz
    - Assume one cycle contains 16 samples
    - Baseband data rate = 1Kbps
    - Assume a 6th order filter with cut-off frequency 0.2 (low pass)
    - Define Amplitude, time
    - Initialize SNR, set value to change plots
    - Initialize error variable
    - Calculate signal length
    - Set number of runs
    - Functions to simulate decision device + sampling
    - Plotting
%}

nBits = 1024;
carrierFrequency = 10000;
carrierSignal = carrierFrequency * 16;
dataRate = 1000;
samplingPeriod = carrierSignal / dataRate;
[lowB, lowA] = butter(6,0.2);
amp = 1;
t = 0: 1/carrierSignal : nBits/dataRate;
SNR_dB = -20:1:20;
SNR = (10.^(SNR_dB/10));
modifySNR_dB = 5;
errorRateOOK = zeros(length(SNR));
carrier = amp .* cos(2*pi*carrierFrequency*t);
signalLength = carrierSignal*nBits/dataRate + 1;
numRuns = 5;

for i = 1 : length(SNR)
    avgErrorOOK = 0;
    
    for j = 1 : numRuns
        data = round(rand(1,nBits));
        dataStream = zeros(1, signalLength);
        
        for k = 1: signalLength - 1
            dataStream(k) = data(ceil(k*dataRate/carrierSignal));
        end
        
        dataStream(signalLength) = dataStream(signalLength - 1);
        OOKSignal = carrier .* dataStream;
        
        % Noise Generation
        OOKSignalPower = (norm(OOKSignal)^2)/signalLength;  
		OOKNoise = OOKSignalPower ./SNR(i);
		OOKNoise = sqrt(OOKNoise/2) .*randn(1,signalLength);
        
        % Transmit signal
		OOKTransmit = OOKSignal + OOKNoise;
        
        % Use non-coherent detection - square law detector
        sqLawOOK = OOKTransmit .* OOKTransmit;
        
        % Pass this through the LP filter
        LPfilterOOK = filtfilt(lowB, lowA, sqLawOOK);
         
        % Sample the signal
        OOKsample = sample(LPfilterOOK, samplingPeriod, nBits);
        finalResultOOK = decision_device(OOKsample,nBits, amp/2); 
        
        % Calculate Error
        errorOOK = 0;
        for k = 1: nBits - 1
            if(finalResultOOK(k) ~= data(k))
                errorOOK = errorOOK + 1;
            end
            avgErrorOOK = errorOOK + avgErrorOOK;
        end 
    end
    
    % Variable Plots
    if (modifySNR_dB == SNR_dB(i))
        plotSignal = data;
        plotOOK = OOKSignal;
        plotOOKTransmit = OOKTransmit;
        plotLPfilterOOK = LPfilterOOK;
        plotfinalResultOOK = finalResultOOK;
    end
    errorRateOOK(i) = (avgErrorOOK / numRuns)/nBits;
end

% Plotting Error + OOK
figure(1);
semilogy (SNR_dB,errorRateOOK,'k-*');
hold off

figure(2);
subplot(511);title('Data Generated: ');plot(plotSignal);
subplot(512);title('Step - Modulation (OOK): ');plot(plotOOK,'k');
subplot(513);title('Signal Recieved: ');plot(plotOOKTransmit, 'k')
subplot(514);title('Step - Demodulation (OOK): ');plot(plotLPfilterOOK, 'k');
subplot(515);title('Decoded: ');plot(plotfinalResultOOK);

% Sampling and Decision Device Simulation
function sampled = sample(x,sampling_period,num_bit)
    sampled = zeros(1, num_bit);
    for n = 1: num_bit
        sampled(n) = x((2 * n - 1) * sampling_period / 2);
    end
end

function binary_out = decision_device(sampled,num_bit,threshold)
    binary_out = zeros(1,num_bit);
    for n = 1:num_bit
        if(sampled(n) > threshold)
            binary_out(n) = 1;
        else 
            binary_out(n) = 0;
        end
    end
end
        

