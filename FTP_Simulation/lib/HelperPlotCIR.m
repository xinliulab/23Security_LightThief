function [] = HelperPlotCIR(h, D2, D3, ToFEstimate, GainEstimate, ToFPlotRange, ToFPlotRange2)    
    fontsize = 20;
    linewidth = 2.5;
    markersz = 8;
    fig_size = [1 1 6 4];
    fig = figure('Units','inches', 'Position', fig_size);
    color = 'brg';
    stem(ToFEstimate(1)*1e9, abs(GainEstimate(1)), 'b-.', 'Linewidth',linewidth, 'MarkerSize', markersz); hold on;
    plot(ToFPlotRange2*1e9, abs(GainEstimate(1).*D3(:,1)), 'b-.', 'Linewidth', linewidth, 'MarkerSize', markersz); hold on;
    
    stem(ToFEstimate(2)*1e9, abs(GainEstimate(2)), 'r:', 'Linewidth', linewidth, 'MarkerSize', markersz); hold on;
    plot(ToFPlotRange2*1e9, abs(GainEstimate(2).*D3(:,2)), 'r:', 'Linewidth', linewidth, 'MarkerSize', markersz); hold on;
    
    plot(ToFPlotRange*1e9, abs(sum(GainEstimate.'.*D2, 2)), 'gs-', 'Linewidth',linewidth); hold on;
    plot(ToFPlotRange*1e9, abs(h), 'ko-', 'Linewidth', linewidth);
    
    hold off; grid on; grid minor;
    title("Channel Impulse Response");
    xlim([0 40]);
    xlabel('ToF (ns)'); 
    ylabel('Normalized magnitude');
    set(gca, 'Fontsize', fontsize);
    legend('', 'Est. path 1', '', 'Est. path 2', 'Fitted CIR', 'Measured CIR', 'Location', 'northeast');
end