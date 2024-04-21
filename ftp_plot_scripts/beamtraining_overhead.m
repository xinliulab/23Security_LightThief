% path(path, "../legendflex-pkg-master/setgetpos_V1.2");
% path(path, "../legendflex-pkg-master/legendflex");
% path(path, "../matlab-hatchfill2-master");
% close all;
color = ['m','c','g']; % CAMEO, ACO, UbiG
sysname = 'FTP';
fontsize = 22;
fig_size = [1 1 6 4];
fname_10a = "../figures/probing_overhead.pdf";
fname_10b = "../figures/computational_overhead.pdf";
fname_10c = "../figures/su_overall_overhead.pdf";
fname_10d = "../figures/mu_overall_overhead.pdf";

K=2;
Nant = [32,256,1024];
Nclient = [1,8]; 
% probing overhead
load("./ftp_probing.mat");
load("./aco_probing.mat");
load("./ubig_probing.mat"); % (Nclients, Nant)

% computation overhead
load("./aco_latency.mat");
load("./ftp_latency.mat");
load("./ubig_latency.mat");

ubig_comp = median(squeeze(ubig_latency(:,K,:)), 1);
aco_comp = aco_latency;
ftp_comp = ftp_latency;

% SU probing
y1 = [ftp_probing(1,:)];
y2 = [aco_probing(1,:)];
y3 = [ubig_probing(1,:)];
y4 = [y1; y2; y3].';
% SU computational
y5 = [ftp_comp];
y6 = [aco_comp];
y7 = [ubig_comp];
y8 = [y5; y6; y7].';
% SU overall
y9 = y4 + y8;
% MU overall, Nant = 32
idx = 2;
y10 = [ftp_probing(2,:) + Nclient(2).*ftp_comp];
y11 = [aco_probing(2,:) + Nclient(2).*aco_comp];
y12 = [ubig_probing(2,:) + Nclient(2).*ubig_comp];
y13 = [y10; y11; y12].';

%%%%%%% 1. SU probing 
% fig = figure('Position', [100 100 200*3 200*2]);
fig = figure('Units','inches', 'Position', fig_size); %6,4 for 2fig/column 
bars = bar(y4);
set(gca,'YScale','log');
for ii=1:3
    bars(ii).FaceColor = color(ii);
end
% apply hatch pattern to bars
hatchfill2(bars(2), 'single', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
hatchfill2(bars(3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
% hatchfill2(bars(3), 'single', 'HatchAngle', -45, 'HatchDensity', 20, 'HatchColor', 'black');
legendData = {sysname, 'ACO', 'UbiG'};
[legend_h, object_h, plot_h, text_str] = legendflex(bars, legendData, 'FontSize', fontsize, ...
    'anchor', [2 2], 'buffer', [10 0],'ncol',3);
% apply hatch pattern to legends
hatchfill2(object_h(3+2), 'single', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
hatchfill2(object_h(3+3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
% hatchfill2(object_h(3+3), 'single', 'HatchAngle', -45, 'HatchDensity', 20/3, 'HatchColor', 'black');

grid on;
% title("SU Probing");
ylabel("Time (s)");
set(gca,'xticklabel', ["N = 32", "N = 256", "N = 1024"]);
set(gca, 'FontSize', fontsize);
set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
set(gca,'ytick', 10.^[-6:2:2]);
ylim([1e-4 1e2]);
exportgraphics(fig,fname_10a,'Resolution',300);


%%%%%%% 2. SU computational 
fig2 = figure('Units','inches', 'Position', fig_size); %6,4 for 2fig/column 
bars = bar(y8);
set(gca,'YScale','log');
for ii=1:3
    bars(ii).FaceColor = color(ii);
end
% apply hatch pattern to bars
hatchfill2(bars(2), 'single', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
hatchfill2(bars(3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
% hatchfill2(bars(3), 'single', 'HatchAngle', -45, 'HatchDensity', 20, 'HatchColor', 'black');
legendData = {sysname, 'ACO', 'UbiG'};
[legend_h, object_h, plot_h, text_str] = legendflex(bars, legendData, 'FontSize', fontsize, ...
    'anchor', [2 2], 'buffer', [10 0],'ncol',3);
% apply hatch pattern to legends
hatchfill2(object_h(3+2), 'single', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
hatchfill2(object_h(3+3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
% hatchfill2(object_h(3+3), 'single', 'HatchAngle', -45, 'HatchDensity', 20/3, 'HatchColor', 'black');

grid on;
% title("SU Computational");
ylabel("Time (s)");
set(gca,'xticklabel', ["N = 32", "N = 256", "N = 1024"]);
set(gca, 'FontSize', fontsize);
set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
set(gca,'ytick', 10.^[-6:2:2]);
ylim([1e-7 1e2]);
exportgraphics(fig2,fname_10b,'Resolution',300);

%%%%%%% 3. SU overall 
fig3 = figure('Units','inches', 'Position', fig_size); %6,4 for 2fig/column 
bars = bar(y9);
set(gca,'YScale','log');
for ii=1:3
    bars(ii).FaceColor = color(ii);
end
% apply hatch pattern to bars
hatchfill2(bars(2), 'single', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
hatchfill2(bars(3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
% hatchfill2(bars(3), 'single', 'HatchAngle', -45, 'HatchDensity', 20, 'HatchColor', 'black');
legendData = {sysname, 'ACO', 'UbiG'};
[legend_h, object_h, plot_h, text_str] = legendflex(bars, legendData, 'FontSize', fontsize, ...
    'anchor', [2 2], 'buffer', [10 0],'ncol',3);
% apply hatch pattern to legends
hatchfill2(object_h(3+2), 'single', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
hatchfill2(object_h(3+3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
% hatchfill2(object_h(3+3), 'single', 'HatchAngle', -45, 'HatchDensity', 20/3, 'HatchColor', 'black');

grid on;
% title("SU beam-training");
ylabel("Time (s)");
set(gca,'xticklabel', ["N = 32", "N = 256", "N = 1024"]);
set(gca, 'FontSize', fontsize);
set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
set(gca,'ytick', 10.^[-6:2:2]);
ylim([1e-4 1e2]);
exportgraphics(fig3,fname_10c,'Resolution',300);


%%%%%%% 4. MU overall 
fig4 = figure('Units','inches', 'Position', fig_size); %6,4 for 2fig/column 
bars = bar(y13);
set(gca,'YScale','log');
for ii=1:3
    bars(ii).FaceColor = color(ii);
end
% apply hatch pattern to bars
hatchfill2(bars(2), 'single', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
hatchfill2(bars(3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
% hatchfill2(bars(3), 'single', 'HatchAngle', -45, 'HatchDensity', 20, 'HatchColor', 'black');
legendData = {sysname, 'ACO', 'UbiG'};
[legend_h, object_h, plot_h, text_str] = legendflex(bars, legendData, 'FontSize', fontsize, ...
    'anchor', [2 2], 'buffer', [10 0],'ncol',3);
% apply hatch pattern to legends
hatchfill2(object_h(3+2), 'single', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
hatchfill2(object_h(3+3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
% hatchfill2(object_h(3+3), 'single', 'HatchAngle', -45, 'HatchDensity', 20/3, 'HatchColor', 'black');

grid on;
% title("MU beam-training");
ylabel("Time (s)");
set(gca,'xticklabel', ["N = 32", "N = 256", "N = 1024"]);
set(gca, 'FontSize', fontsize);
set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
set(gca,'ytick', 10.^[-6:2:2]);
ylim([1e-4 2e2]);
exportgraphics(fig4,fname_10d,'Resolution',300);