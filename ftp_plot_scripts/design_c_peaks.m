tof = [35.6 42.4]*1e-9;
mag = [.8 .4; ...
       .6 .1; ...
       .95 .7];
t=[20:0.2:70]*1e-9;

% close all;
fig_size = [1 1 6 6 ];
% fig = figure('Position', [100 100 200*3 200*2]);
fig = figure('Units','inches', 'Position', fig_size);
color = 'brg';
fontsize = 20;
linewidth = 2.5;
markersz = 8;
% fig = figure('Position', [100 100 200*3 200*3]);
% linewidth = 2.5;
% markersz = 7;
% fontsize = 18;
for ii=1:3
    subplot(3,1,ii);
    stem(tof(1)*1e9, mag(ii,1), 'b.','LineWidth',linewidth,'MarkerSize',markersz);hold on;
    stem(tof(2)*1e9, mag(ii,2), 'r.','LineWidth',linewidth,'MarkerSize',markersz);hold on;
    xlim([33 45]);
    ylim([0 1]);
    xticks(33:3:45);
    set(gca,'fontsize',fontsize)
%     if ii==2
%         ylabel('Normalized magnitude')
%     end
end
xlabel("ToF (ns)")
% sgtitle("CIR");
exportgraphics(fig,"../figures/design_probes1.png",'Resolution',300);

% fig = figure('Position', [100 100 200*3 200*1]);
% stem(tof(1)*1e9, mag(3,1), 'b.','LineWidth',linewidth,'MarkerSize',markersz);hold on;
% stem(tof(2)*1e9, mag(3,2), 'r.','LineWidth',linewidth,'MarkerSize',markersz);hold on;
% xlim([33 45]);
% ylim([0 1]);
% xticks(33:3:45);
% set(gca,'fontsize',fontsize)
% xlabel("TOF (ns)")
% % sgtitle("CIR");
% exportgraphics(fig,"./figures/design_probes2.png",'Resolution',300);