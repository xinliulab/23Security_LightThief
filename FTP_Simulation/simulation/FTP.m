close all; clear;
%%%%%%%%%%%% 1. Simulation Parameters %%%%%%%%%%%%%%%%%%%%%%
rng(1);
Params.SIM = 0; % Set as zero to load experimental data 
Params.SNR = 15;
Params.Fc = 60.48e9; % 802.11ad SC PHY
Params.Fs = 1.76e9; % 802.11ad SC PHY
Params.CFO = Params.Fc*12e-6; % 12 ppm CFO
Params.N = 36; % 6x6 URA
Params.M = round(3*log2(Params.N)); % number of TX probes
Params.Lambda = physconst('LightSpeed')/Params.Fc;
Params.PhaseQuantizeBit = 2; % 2-bit phase control and 1-bit amplitude control
Params.PhasedArray = phased.URA('Size',sqrt(Params.N), 'ElementSpacing',Params.Lambda/2);
Params.Beamwidth = beamwidth(Params.PhasedArray,Params.Fc);
scaler = 2*pi/(2^Params.PhaseQuantizeBit);
% RX uses a fixed receive beam u
Params.u = normalize(exp(1j*(randi(2^Params.PhaseQuantizeBit, Params.N, 1)-1)*scaler), 'norm');
% TX sends M probes in total
Params.v = normalize(exp(1j*(randi(2^Params.PhaseQuantizeBit, Params.N, Params.M)-1)*scaler), 'norm');
Params.Multipath = [1,                           25e-9,     -30,  30; ...
                                 0.75*exp(1j*2.15),  41e-9,      42,  -10]; % (Gain, ToF, AoD, AoA)
% 802.11ad preamble, see 802.11ad section 21.3.6.3
[Ga128,Gb128] = wlanGolaySequence(128);
Params.Gu = [-Gb128; -Ga128; Gb128; -Ga128];
Params.Gv = [-Gb128; Ga128; -Gb128; -Ga128];
Params.STF = dmgRotate([repmat(Ga128,16,1); -Ga128]);
Params.CE = dmgRotate([Params.Gu;Params.Gv;-Gb128]);
Params.Preamble = [Params.STF;Params.CE];

if Params.SIM ==1
    %%%%%%%%%%%% 2. Generate Multipath Channel and Time-domain Samples %%%%
    % y: Time-domain samples, H: Multipath channel
    [y, H] = GetTimeDomainSamples(Params);
    
    %%%%%%%%%%%% 3. Extract Channel Impulse Response (CIR) %%%%%%%%%%%
    % P_mk: peaks in the CIR, Eqn. (2)
    [P_mk, PathToF] = GetChannelImpulseResponse(y, Params);
    
    %%%%%%%%%%%% 4. Construct the Optimal Beam %%%%%%%%%%%%%%%%%%
    % Compressive Path Direction Estimation, Eqn. (11)
    [AoD] = CompressivePathDirectionEstimation(P_mk, PathToF, Params);
    % Relative Path Gain Estimation, Eqn. (14)
    [RelativeGains] = GetRelativeGains(P_mk, PathToF, AoD, Params);
    % Construct the Optimal Beam, Eqn. (15)
    [v_star] = GetOptimalBeam(AoD, RelativeGains, Params);
    
    %%%%%%%%%%%% 5. Plotting Results %%%%%%%%%%%%%%%%%%%%%%%%
    v_GroundTruthOptimal = normalize((Params.u'*H)', 'norm');
    HelperPlotBeamPatterns([v_star v_GroundTruthOptimal], Params, ["FTP", "Global Optimum"]);
else
    %%%%%%%%%%%% 3. Extract Channel Impulse Response (CIR) %%%%%%%%%%%
    % Load experimental data of 16 beam probes
    load("./data/PathToF.mat");
    load("./data/P_mk.mat");
    load("./data/pa.mat");
    load("./data/v.mat");
    Params.PhasedArray = pa;
    Params.v = v;
    %%%%%%%%%%%% 4. Construct the Optimal Beam %%%%%%%%%%%%%%%%%%
    % Compressive Path Direction Estimation, Eqn. (11)
    [AoD] = CompressivePathDirectionEstimation(P_mk, PathToF, Params);
    % Relative Path Gain Estimation, Eqn. (14)
    [RelativeGains] = GetRelativeGains(P_mk, PathToF, AoD, Params);
    % Construct the Optimal Beam, Eqn. (15)
    [v_star] = GetOptimalBeam(AoD, RelativeGains, Params);
    % Quantization
    v_star = QuantizePhase(v_star, 2);
    %%%%%%%%%%%% 5. Plotting Results %%%%%%%%%%%%%%%%%%%%%%%%
    load("./data/v_ACO.mat");
    v_GroundTruthOptimal = QuantizePhase(v_ACO, 2);
    HelperPlotBeamPatternsExpData([v_star v_GroundTruthOptimal], Params, ["FTP", "ACO"]);
end