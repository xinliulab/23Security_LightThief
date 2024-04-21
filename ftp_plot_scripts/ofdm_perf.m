% close all;
fontsize = 22;
fig_size = [1 1 6 4];
linewidth = 2.5;
markersz = 8;
sysname = "FTP";
color = ['m','k','c']; % CAMEO, ACO, UbiG
fname_12b = "../figures/ofdm_snr.pdf";


fig = figure('Units','inches', 'Position', fig_size);
hold on;
y3 = 8.4840; %[data.snr_cs_multipath]; 
y4 = 6.9354; %[data.snr_11ad];
bars(1) = bar(1,[y3]);
bars(2) = bar(2,[y3]*0);
bars(3) = bar(3,[y4]);

% set(gca,'YScale','log');
% ylim([5e-7 1e2]);
% change facecolor
for ii=1:3
    bars(ii).FaceColor = color(ii);
end
bars(3).FaceColor = [0.75 0.75 0.75];    
% apply hatch pattern to bars
% hatchfill2(bars(1), 'single', 'HatchAngle', 45, 'HatchDensity', 40, 'HatchColor', 'black');
% hatchfill2(bars(2), 'single', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
% hatchfill2(bars(2), 'cross', 'HatchAngle', 45, 'HatchDensity', 40, 'HatchColor', 'black');
% hatchfill2(bars(4), 'cross', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
% hatchfill2(bars(5), 'single', 'HatchAngle', -45, 'HatchDensity', 40, 'HatchColor', 'black');
% hatchfill2(bars(6), 'single', 'HatchAngle', -45, 'HatchDensity', 20, 'HatchColor', 'black');
% legendData = {'CAMEO','Baseline'};
% [legend_h, object_h, plot_h, text_str] = legendflex(bars, legendData, 'FontSize', fontsize, ...
%     'anchor', [3 3], 'buffer', [-10 -10],'ncol',1);
% apply hatch pattern to legends
% hatchfill2(object_h(2+1), 'single', 'HatchAngle', 45, 'HatchDensity', 40/3, 'HatchColor', 'black');
% hatchfill2(object_h(6+2), 'single', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
% hatchfill2(object_h(2+2), 'cross', 'HatchAngle', 45, 'HatchDensity', 40/3, 'HatchColor', 'black');
% hatchfill2(object_h(6+4), 'cross', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
% hatchfill2(object_h(6+5), 'single', 'HatchAngle', -45, 'HatchDensity', 40/3, 'HatchColor', 'black');
% hatchfill2(object_h(6+6), 'single', 'HatchAngle', -45, 'HatchDensity', 20/3, 'HatchColor', 'black');

grid on;
ylabel("SNR (dB)");
set(gca,'xtick', [1,2 3]);
set(gca,'xticklabel', [sysname,"","Baseline"]);
set(gca, 'FontSize', fontsize);
% set(legend_h,'fontsize',13);
set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
exportgraphics(fig,fname_12b,'Resolution',300);