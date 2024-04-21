% close all;
fontsize = 18;
fig_size = [1 1 6 3];
linewidth = 2.5;
markersz = 8;
sysname = "FTP";
fname_12a = "../figures/ofdm_beam.pdf";

az=[-90:1:90];
el=[-50:1:50];
fig = figure('Units','inches', 'Position', fig_size);
color = 'brg';
load("PAT_azcut.mat");
I2 = 83;
I4 = 50;
% PAT_azcut = squeeze(PAT_CAMEO(find(EL_ANG==0),:));
PAT_azcut_db = db(PAT_azcut, 'power');
polarplot(deg2rad(az), PAT_azcut_db, ['m-'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
polarplot(deg2rad(az(I2))*ones(1,2), [-35 0], ['k--'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
polarplot(deg2rad(az(I4))*ones(1,2), [-35 0], ['k--'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
ax = gca;
% ax.RTickLabel = {""}; % remove ticklabels
% subtitle("Normalized gain (dB)", "Position",[0,-47]);
ax.ThetaDir = 'clockwise';
set(gca,'ThetaZeroLocation','top','FontSize',fontsize)
set(gca,'fontsize',fontsize)
% thetaticks(-90:30:90);
thetalim([-90 90]);
rlim([-35 0]);
legend([sysname, "Ground truth"], 'Location', 'northoutside', 'NumColumns',2, 'Fontsize',fontsize);
exportgraphics(fig,fname_12a,'Resolution',300);