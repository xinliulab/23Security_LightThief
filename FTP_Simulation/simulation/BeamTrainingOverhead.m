close all; clear;
%%%%%%%%%%%% 1. Simulation Parameters %%%%%%%%%%%%%%%%%%%%%%
Params.NumAntenna = [32, 256, 1024];
Params.NumClient = [1, 8];
Params.K = 2;
Params.ACOprobes = Params.NumAntenna + 4*(Params.NumAntenna-1);
% aco_ref_beam_probes = 32;
% aco_probes = 3*Nant +1; %Nant+4*(Nant-1);
Params.FTPprobes = Params.K*log2(Params.NumAntenna);
Params.UbiGprobes = (4*Params.K + 8)*ones(1, length(Params.NumAntenna));
Params.BeaconSlots = 64;
Params.ABFTSlots = 8; % up to 8
Params.SSWperABFT = 16; % up to 16
Params.Fs = 1.76e9;
Params.SSWFrameDuration = 17.6e-6; % 26 bytes sent through Control PHY
Params.BeaconInterval = 100e-3;

%%%%%%%%%%%% 2. Probing Overhead %%%%%%%%%%%%%%%%%%%%%%%%
Params.FTPprobing = zeros(length(Params.NumClient), length(Params.NumAntenna));
Params.ACOprobing = zeros(length(Params.NumClient), length(Params.NumAntenna));
Params.UbiGprobing= zeros(length(Params.NumClient), length(Params.NumAntenna));

for ii=1:length(Params.NumClient)
    for jj=1:length(Params.NumAntenna)
        % FTP
        r = mod(Params.FTPprobes(jj)*Params.NumClient(ii), Params.ABFTSlots*Params.SSWperABFT);
        q = floor(Params.FTPprobes(jj)*Params.NumClient(ii) / (Params.ABFTSlots*Params.SSWperABFT));
        Params.FTPprobing(ii, jj) =  Params.FTPprobes(jj)*Params.SSWFrameDuration + ...
            Params.BeaconInterval*(q-1*(r==0));
        % ACO
%         n = (aco_ref_beam_probes + aco_probes(jj))*Nclient(ii);
        r = mod(Params.ACOprobes(jj)*Params.NumClient(ii), Params.ABFTSlots*Params.SSWperABFT);
        q = floor(Params.ACOprobes(jj)*Params.NumClient(ii) / (Params.ABFTSlots*Params.SSWperABFT));
        Params.ACOprobing(ii, jj) =  Params.ACOprobes(jj)*Params.SSWFrameDuration + ...
            Params.BeaconInterval*(q-1*(r==0));
        % UbiG
        r = mod(Params.UbiGprobes(jj)*Params.NumClient(ii), Params.ABFTSlots*Params.SSWperABFT);
        q = floor(Params.UbiGprobes(jj)*Params.NumClient(ii) / (Params.ABFTSlots*Params.SSWperABFT));
        Params.UbiGprobing(ii, jj) =  Params.UbiGprobes(jj)*Params.SSWFrameDuration + ...
            Params.BeaconInterval*(q-1*(r==0));
    end
end

%%%%%%%%%%%% 3. Computational Overhead %%%%%%%%%%%%%%%%%%%%%
load("FTPcomputation.mat"); % dimension (K, NumAntenna)
load("ACOcomputation.mat"); % dimension (1, NumAntenna)
load("UbiGcomputation.mat"); % dimension (K, NumAntenna)
Params.FTPcomputation = FTPcomputation;
Params.ACOcomputation = ACOcomputation;
Params.UbiGcomputation = UbiGcomputation;

%%%%%%%%%%%% 4. Plot Results %%%%%%%%%%%%%%%%%%%%%%%%%%%
HelperPlotBeamTrainingOverhead(Params);