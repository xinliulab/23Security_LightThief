PA.FREQ          = 60480e6;
PA.LAM           = physconst('LightSpeed')/PA.FREQ;
PA.ANT_MAP       = containers.Map({'row1','row2','row3','row4','col1','24','32'},{[8 1 2 11 13 15],[6 7 5 9 16 14],[22 23 21 26 32 30],[24 17 18 27 29 31],[3 1 7 23 17 19],setdiff([1:32],[3 4 12 10 19 20 28 25]), [1:32]});
PA.ACTIVE_ANT    = PA.ANT_MAP('32');%setdiff([1:32],[3 4 12 10 19 20 28 25])
PA.PHASE_CAL     = zeros(32,1); % in rad
PA.MAG_CAL       = ones(4,32);
load("cal32_new_taoffice.mat"); % somhow this still works for node 1 mod 5
PA.PHASE_CAL(PA.ACTIVE_ANT) = calibration_vec;
load("magcal.mat");
PA.MAG_CAL = mag_cal_vec;


az=[-90:1:90];
el=[-50:1:50];
pa = get_phased_array(PA.FREQ);
sv = sum(steervec(pa.getElementPosition()/PA.LAM, [-30 45;0 0]),2);
[PAT_1,AZ_ANG,EL_ANG] = pattern(pa,PA.FREQ,az,el,...
    'PropagationSpeed',physconst('LightSpeed'),'Type','power','Normalize',true,...
    'CoordinateSystem','polar','Weights',sv);

fig_size = [1 1 6 4];
% fig = figure('Position', [100 100 200*3 200*2]);
fig = figure('Units','inches', 'Position', fig_size);
color = 'brg';
fontsize = 22;
linewidth = 4;
markersz = 8;
PAT_azcut = squeeze(PAT_1(find(EL_ANG==0),:));
PAT_azcut_db = db(PAT_azcut, 'power');
polarplot(deg2rad(az), PAT_azcut_db, ['k-.'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
polarplot(deg2rad(-30)*ones(1,2), [-35 0], ['b--'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
polarplot(deg2rad(45)*ones(1,2), [-35 0], ['r--'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
ax = gca;
ax.RTickLabel = {""}; % remove ticklabels
% subtitle("Normalized gain (dB)", "Position",[0,-47]);
ax.ThetaDir = 'clockwise';
set(gca,'ThetaZeroLocation','top','FontSize',fontsize)
% thetaticks(-90:30:90);
thetalim([-90 90]);
rlim([-35 0]);
% legend(["CAMEO", "Ground truth"], 'Location', 'northoutside', 'NumColumns',2, 'Fontsize',fontsize);
% exportgraphics(fig,"./figures/ofdm_beam.pdf",'Resolution',300);
exportgraphics(fig,"../figures/design_beam.png",'Resolution',300);