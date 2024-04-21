% path(path, "../legendflex-pkg-master/setgetpos_V1.2");
% path(path, "../legendflex-pkg-master/legendflex");
% path(path, "../matlab-hatchfill2-master");

color = ['m','c','g']; % CAMEO, ACO, UbiG
sysname = 'FTP';
fname_1 = "../figures/beamtraining_overhead.pdf";

K=2;
Nant = [32,256,1024];
% probing overhead
load("ftp_probing.mat");
load("aco_probing.mat");
load("ubig_probing.mat"); % (Nclients, Nant)

% computation overhead
load("ftp_latency.mat");
load("aco_latency.mat");
load("ubig_latency.mat");


ubig_comp = median(squeeze(ubig_latency(:,K,:)), 1);
aco_comp = aco_latency;
ftp_comp = ftp_latency;

y1 = [ftp_probing(1,[1 3])+ftp_comp([1 3])]; % (Nclients, Nant)
y2 = [aco_probing(1,[1 3])+aco_comp([1 3])];
y3 = [ubig_probing(1,[1 3])+ubig_comp([1 3])];
y4 = [y1; y2; y3].';

fontsize = 15;
fig_size = [1 1 6 3];
close all;
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
    'anchor', [1 1], 'buffer', [0 0],'ncol',3);
% apply hatch pattern to legends
hatchfill2(object_h(3+2), 'single', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
hatchfill2(object_h(3+3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
% hatchfill2(object_h(3+3), 'single', 'HatchAngle', -45, 'HatchDensity', 20/3, 'HatchColor', 'black');

grid on;
ylabel("Beam-training Overhead (s)");
set(gca,'xticklabel', ["32-element antenna", "1024-element antenna"]);
set(gca, 'FontSize', fontsize);
set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
set(gca,'ytick', 10.^[-6:2:2]);
ylim([1e-4 3e2]);

% Create doublearrow
annotation(fig,'doublearrow',[0.234083333333333 0.234083333333333],...
    [0.168 0.598000000000001]);

% Create doublearrow
annotation(fig,'doublearrow',[0.627 0.627],[0.21 0.689999999999999]);

% Create textbox
annotation(fig,'textbox',...
    [0.545 0.68113888637225 0.343750007781718 0.130277780294418],...
    'String','~10000x faster',...
    'FontWeight','bold',...
    'FontSize',fontsize,...
    'EdgeColor','none');

% Create textbox
annotation(fig,'textbox',...
    [0.159194444444444 0.583833330816695 0.320138896107674 0.130277780294418],...
    'String',{'~1000x faster'},...
    'FontWeight','bold',...
    'FontSize',fontsize,...
    'EdgeColor','none');

exportgraphics(fig,fname_1,'Resolution',300);