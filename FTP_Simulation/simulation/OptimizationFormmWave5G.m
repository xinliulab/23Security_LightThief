close all; clear;
%%%%%%%%%%%% 1. Simulation Parameters %%%%%%%%%%%%%%%%%%%%%%
rng(1);
% 5G NR numerology mu =3 (see TS 38.211 v17.2 Table 4.2-1)
Params.SubcarrierSpacing = 120e3;
Params.FFTsize = 4096;
Params.NumEffectiveSubcarriers = 3300; % 400 MHz system bandwidth
Params.EffectiveSubcarriers = [-floor(Params.NumEffectiveSubcarriers/2):floor(Params.NumEffectiveSubcarriers/2)-1+mod(Params.NumEffectiveSubcarriers,2)];
Params.AnalogBandwidth = Params.NumEffectiveSubcarriers*Params.SubcarrierSpacing;
Params.SamplingRate = Params.SubcarrierSpacing*Params.FFTsize;
Params.SNR = 15;
% Simulate two close-by paths that cannot be resolved by the given RF bandwidth
Params.PathToF = [15e-9, 15e-9+0.65/Params.AnalogBandwidth];
Params.PathGain = [1,  0.75*exp(1j*2.15)];
% Discretize ToF search points to increments of one tenth of the resolution
Params.SuperResolution = 10;
% Assume all paths have distances less than 300 meters
assert(all(Params.PathToF<1e-6));

%%%%%%%%%%%% 2. Distinguish Paths Through Optimization %%%%%%%%%%%%%
ToFinSample = Params.PathToF.*Params.SamplingRate;
% Obtain the frequency-domain channel
Heff = zeros(Params.FFTsize, 1);
Heff(1+mod(Params.EffectiveSubcarriers, Params.FFTsize)) = ...
    sum(Params.PathGain.*exp(-1j*2*pi*(Params.EffectiveSubcarriers.')/Params.FFTsize.*ToFinSample), 2);
% Add noise according to the SNR
HeffNoise = awgn(Heff, Params.SNR, 'measured');
% Obtain the time-domain CIR
CIR = fftshift(ifft(HeffNoise));
[M, I] = max(abs(CIR));
% Optimize over the 128-sample CIR by solving Eqn. (13)
NumCIRSamples = 128;
h = CIR(I-NumCIRSamples/2: I+NumCIRSamples/2-1);
% Create sincs centered at ToFs within the search range 
ToFSearchRange = [-2/Params.SamplingRate: 1/(Params.SuperResolution*Params.SamplingRate): 2/Params.SamplingRate];
T = [-NumCIRSamples/2: NumCIRSamples/2-1]/Params.SamplingRate;
[T2, Tau2] = ndgrid(T, ToFSearchRange); 
D = sinc(Params.AnalogBandwidth*(T2-Tau2)); 
n = size(D, 2);
lambda = 0.7; % hyperparameter
% Solve the L1-regularized least-sqares
cvx_begin
    variable x(n) complex
    minimize( norm(D*x - h) + lambda*norm(x, 1) )
cvx_end
% Positions of non-zero entries of x give the path ToFs
[~,Loc,~,Prominence] = findpeaks(abs(x)./max(abs(x)),"MinPeakProminence", 0.1, "MinPeakHeight", 0.1);
[T3, Tau3] = ndgrid(T, ToFSearchRange(Loc));
D2 = sinc(Params.AnalogBandwidth*(T3-Tau3));
% Solve for the complex gains of each path
GainEstimate = pinv(D2)*h;
ToFEstimate = ToFSearchRange(Loc) + (I-Params.FFTsize/2-1)/Params.SamplingRate;

%%%%%%%%%%%% 3. Plot Results %%%%%%%%%%%%%%%%%%%%%%%%%%%
ToFPlotRange = T + (I-Params.FFTsize/2-1)/Params.SamplingRate;
ToFPlotRange2 = [T(1): 1/(Params.SuperResolution*Params.SamplingRate): T(end) ] + (I-Params.FFTsize/2-1)/Params.SamplingRate;
[T4, Tau4] = ndgrid(ToFPlotRange2, ToFEstimate);
D3 = sinc(Params.AnalogBandwidth*(T4-Tau4));
HelperPlotCIR(h, D2, D3, ToFEstimate, GainEstimate, ToFPlotRange, ToFPlotRange2);  