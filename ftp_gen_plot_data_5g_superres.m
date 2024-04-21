% run('./cvx-w64/cvx/cvx_setup.m')

load("D:/Lab computer/mmw-calibration-sim/exp_data/swift2.0/ofdm-5gNR/data1.mat");
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
% sv2beam(sv,[-90:1:90],[-50:1:50],PA,legs)

if BPU.DO_OFDM == 1
    PA.N_BEAM = length(data.aco_cbsize);
    [H40, r40, SNR40, n40, BPU, PA, maxk_pos40, maxk_pks40]=debug_peaks(data.rx_cs_multipath, BPU, PA);
    [maxk_pos41, maxk_pks41] = super_resolution(H40,0,[12]);
%     [maxk_pos41, maxk_pks41] = super_resolution(H40,0,logspace( -2, 1, 20 ));
end
pa = get_phased_array(PA.FREQ);

% super res
H = H40;
save("./ftp_plot_scripts/H.mat", "H");

% beam plot
az=[-90:1:90];
el=[-50:1:50];

sv2 = exp(-1j*2*pi/4.*sv2psh(v2./exp(1j*PA.PHASE_CAL)));
[PAT_1,AZ_ANG,EL_ANG] = pattern(pa,PA.FREQ,az,el,...
    'PropagationSpeed',physconst('LightSpeed'),'Type','power','Normalize',true,...
    'CoordinateSystem','polar','Weights',sv2);
sv3 = exp(-1j*2*pi/4.*sv2psh(aco_sv./exp(1j*PA.PHASE_CAL)));
[PAT_2,AZ_ANG,EL_ANG] = pattern(pa,PA.FREQ,az,el,...
    'PropagationSpeed',physconst('LightSpeed'),'Type','power','Normalize',true,...
    'CoordinateSystem','polar','Weights',sv3);

% find angles from ACO
PAT_ACO = PAT_2;
PAT_CAMEO = PAT_1;
% path ang 1
[C,I] = max(PAT_ACO(:));
[I1,I2] = ind2sub(size(PAT_ACO),I);
fprintf("max az=%d, el=%d\n",az(I2), el(I1));
% path ang 2
PAT_ACO = squeeze(PAT_2(:,1:find(az==-20)));
[C,I] = max(PAT_ACO(:));
[I3,I4] = ind2sub(size(PAT_ACO),I);
fprintf("max az=%d, el=%d\n",az(I4), el(I3));
PAT_azcut = squeeze(PAT_CAMEO(find(EL_ANG==0),:));
save("./ftp_plot_scripts/PAT_azcut.mat", "PAT_azcut");


% fig = figure('Units','inches', 'Position', fig_size);
% color = 'brg';
% PAT_azcut_db = db(PAT_azcut, 'power');
% polarplot(deg2rad(az), PAT_azcut_db, ['b-'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
% polarplot(deg2rad(az(I2))*ones(1,2), [-35 0], ['k--'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
% polarplot(deg2rad(az(I4))*ones(1,2), [-35 0], ['k--'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
% ax = gca;
% % ax.RTickLabel = {""}; % remove ticklabels
% % subtitle("Normalized gain (dB)", "Position",[0,-47]);
% ax.ThetaDir = 'clockwise';
% set(gca,'ThetaZeroLocation','top','FontSize',fontsize)
% set(gca,'fontsize',fontsize)
% % thetaticks(-90:30:90);
% thetalim([-90 90]);
% rlim([-35 0]);
% legend([sysname, "Ground truth"], 'Location', 'northoutside', 'NumColumns',2, 'Fontsize',fontsize);
% exportgraphics(fig,"./figures/ofdm_beam.pdf",'Resolution',300);
