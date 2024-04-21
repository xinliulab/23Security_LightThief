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
el=[0];
pa = get_phased_array(PA.FREQ);
% PA.N_BEAM = 10;
create_cs_codebook(10, PA);
cb = "./codebooks/cs.mat";
bp = create_beam_pattern(cb,el,az,PA);


fig_size = [1 1 6 4];
% fig = figure('Position', [100 100 200*3 200*2]);
fig = figure('Units','inches', 'Position', fig_size);
color = 'brg';
fontsize = 22;
linewidth = 6;
markersz = 8;
beam1 = db(squeeze(bp(1,1,:)), 'power');
beam2 = db(squeeze(bp(5,1,:)), 'power');
beam3 = db(squeeze(bp(9,1,:)), 'power');

polarplot(deg2rad(az), beam1-max(beam1), ['k-.'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
polarplot(deg2rad(az), beam2-max(beam2), ['c-'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
polarplot(deg2rad(az), beam3-max(beam3), ['m:'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
ax = gca;
ax.RTickLabel = {""};     % remove ticklabels
ax.ThetaTickLabel = {""}; % remove ticklabels
% subtitle("Normalized gain (dB)", "Position",[0,-30]);
ax.ThetaDir = 'clockwise';
set(gca,'ThetaZeroLocation','top','FontSize',fontsize)
set(gca, 'color', 'none');
% thetaticks(-90:30:90);
thetalim([-90 90]);
rlim([-20 0]);
% legend(["CAMEO", "Ground truth"], 'Location', 'northoutside', 'NumColumns',2, 'Fontsize',fontsize);
% exportgraphics(fig,"./figures/ofdm_beam.pdf",'Resolution',300);
exportgraphics(fig,"./figures/pseudorandom_beams.png",'Resolution',300);