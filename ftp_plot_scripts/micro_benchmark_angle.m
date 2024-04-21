% close all;
fontsize = 18;
linewidth = 2;
markersz = 16;
fig_size = [1 1 6 3];
for ii=1:3
    fname1 = sprintf("../figures/micro_ang%d.pdf",ii);
    load(sprintf("./fig7_%d.mat",ii));
    vary_ang =[-20:20];

    fig = figure('Units','inches', 'Position', fig_size); %6,4 for 2fig/column 
    hold on;
    clims = [-5 0];
    imagesc(data.x, data.y , data.z, clims); 
    plot(data.x2, data.y2, 'k^', 'MarkerSize', markersz, 'MarkerFaceColor', 'k');
    plot(data.x3, data.y3, 'kd', 'MarkerSize', markersz, 'MarkerFaceColor', 'k');
    c=colorbar;
    ylabel(c, "SNR (dB)",'fontsize',fontsize);
    colormap jet;
    xlim(data.x3+[vary_ang(1) vary_ang(end)]);
    ylim(data.y3+[vary_ang(1) vary_ang(end)]);
    legend([sprintf("Oracle"),sprintf("Estimated")],'Location','northeast');
    xlabel("\theta_2 (degree)", 'Interpreter','tex'); % Path 2 
    ylabel("\theta_1 (degree)", 'Interpreter','tex'); % Path 1 
    % xlim(phase1+[vary_phase(1) vary_phase(end)]);  ylim([min(snr_db1) 0]);
    set(gca,'FontSize',fontsize);
    % set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
    exportgraphics(fig,fname1,'Resolution',300);
end