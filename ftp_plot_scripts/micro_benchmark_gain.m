% close all;
fontsize = 18;
linewidth = 2;
markersz = 16;
fig_size = [1 1 6 3];
for ii=1:3
    fname2 = sprintf("../figures/micro_phase_mag%d.pdf",ii);
    load(sprintf("./fig8_%d.mat",ii));
    vary_phase = [-180:1:180]; % degree
    vary_amp = db2mag([-10:10]); % db
       
    fig = figure('Units','inches', 'Position', fig_size); %6,4 for 2fig/column 
    hold on;
    clims = [-5 0];
    imagesc(data.x,data.y,data.z, clims); 
    plot(data.x2, data.y2, 'k^', 'MarkerSize', markersz, 'MarkerFaceColor', 'k');
    plot(0, 0, 'kd', 'MarkerSize', markersz, 'MarkerFaceColor', 'k');
    c=colorbar;
    ylabel(c, "SNR (dB)",'fontsize',fontsize);
    colormap jet;
    xlim([vary_phase(1) vary_phase(end)]);
    ylim([mag2db(vary_amp(1)) mag2db(vary_amp(end))]);
    legend([sprintf("Oracle"),sprintf("Estimated")],'Location','northeast');
    xlabel("Phase \phi (degree)", 'Interpreter','tex'); %Relative phase 
    ylabel("Magnitude a (dB)", 'Interpreter','tex'); %Relative magnitude 
    % xlim(phase1+[vary_phase(1) vary_phase(end)]);  ylim([min(snr_db1) 0]);
    set(gca,'FontSize',fontsize);
    % set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
    exportgraphics(fig,fname2,'Resolution',300);
end