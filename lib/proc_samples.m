load("./exp_data/data3.mat");
% load("./exp_data/calibration/data8.mat");
% load("./exp_data/swift2.0/nlos_multipath/data20.mat");
% load("./exp_data/swift2.0/micro-benchmark/data3.mat");
% load("./exp_data/swift2.0/ofdm-5gNR/data1.mat");
% save_folder = "./exp_data/swift2.0/micro-benchmark";
% load(sprintf("%s/data2.mat",save_folder));
BPU = data.bpu;
PA =  data.pa;
PA.N_BEAM = 124;
create_cs_codebook(124, PA);
cb = "./codebooks/cs.mat";
[H30, r30, SNR30, n30, BPU, PA, maxk_pos30, maxk_pks30]=debug_peaks(data.rx_cs_probes, BPU, PA);
if BPU.DO_OFDM == 1
    [maxk_pos11, maxk_pks11] = super_resolution(H30,0);
else
    maxk_pos11 = maxk_pos30;
    maxk_pks11 = maxk_pks30;
end
[v_multipath,v2_multipath,v_dominantpath,path_ang,path_gain,unique_pos] = ftp_algo(cb, BPU, PA, maxk_pos11, maxk_pks11, SNR30, data.rx_cs_probes, r30,1);

% PA.N_BEAM = length(data.az);
% [H29, r29, SNR29, n29, BPU, PA, maxk_pos29, maxk_pks29]=debug_peaks(data.rx_ex_probes, BPU, PA);
% figure; plot(data.az, r29);

v2 = v_multipath./v_multipath(1).*exp(1j*PA.PHASE_CAL);
v3 = v_dominantpath./v_dominantpath(1).*exp(1j*PA.PHASE_CAL);
v4 = v2_multipath./v2_multipath(1).*exp(1j*PA.PHASE_CAL);

PA.N_BEAM = 124;
[H31, r31, SNR31, n31, BPU, PA, maxk_pos31, maxk_pks31]=debug_peaks(data.rx_aco_probes, BPU, PA);
[rel_phase,rel_phase_avg,rel_phase_std] = get_rel_phase(r31);
aco_activated_ant = [1:1+124/4];
aco_sv = exp(1j*[0;-rel_phase_avg(aco_activated_ant(2:end)-1)]);
% aco_sv = sum(steervec(pa.getElementPosition()/PA.LAM, [-30 45;0 0]),2).*exp(1j*PA.PHASE_CAL);

sv = [v2 aco_sv];
legs = ["SWIFT", "ACO"];
% legs = [sprintf("SWIFT,%.1f",data.snr_cs_multipath(end)), ...
%     sprintf("CS,%.1f",data.snr_cs_dominantpath(end)), ...
%     sprintf("ACO,%.1f (ad,%.1f)",data.snr_aco(end),data.snr_11ad(end))];
sv2beam(sv,[-90:1:90],[-50:1:50],PA,legs)

if BPU.DO_OFDM == 1
    PA.N_BEAM = length(data.aco_cbsize);
    [H40, r40, SNR40, n40, BPU, PA, maxk_pos40, maxk_pks40]=debug_peaks(data.rx_cs_multipath, BPU, PA);
    [maxk_pos41, maxk_pks41] = super_resolution(H40,1,[12]);
%     [maxk_pos41, maxk_pks41] = super_resolution(H40,0,logspace( -2, 1, 20 ));
end