function [] = HelperPlotBeamTrainingOverhead(Params)
    color = ['m','c','g']; % FTP, ACO, UbiG
    sysname = 'FTP';

    % SU probing
    y1 = [Params.FTPprobing(1,:)]; % (NumClient, NumAntenna)
    y2 = [Params.ACOprobing(1,:)];
    y3 = [Params.UbiGprobing(1,:)];
    y4 = [y1; y2; y3].';
    % SU computational
    y5 = [Params.FTPcomputation(Params.K, :)];
    y6 = [Params.ACOcomputation];
    y7 = [Params.UbiGcomputation(Params.K, :)];
    y8 = [y5; y6; y7].';
    % SU overall
    y9 = y4 + y8;
    % MU overall, NumAntenna = 32
    idx = 2;
    y10 = [Params.FTPprobing(2,:) + Params.NumClient(2).*Params.FTPcomputation(Params.K, :)];
    y11 = [Params.ACOprobing(2,:) + Params.NumClient(2).*Params.ACOcomputation];
    y12 = [Params.UbiGprobing(2,:) + Params.NumClient(2).*Params.UbiGcomputation(Params.K, :)];
    y13 = [y10; y11; y12].';
    
    %%%%%%% 1. SU probing 
    fontsize = 22;
    fig_size = [1 1 6 4];
    fig = figure('Units','inches', 'Position', fig_size); 
    bars = bar(y4);
    set(gca,'YScale','log');
    for ii=1:3
        bars(ii).FaceColor = color(ii);
    end
    % apply hatch pattern to bars
    hatchfill2(bars(2), 'single', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
    hatchfill2(bars(3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
    legendData = {sysname, 'ACO', 'UbiG'};
    [legend_h, object_h, plot_h, text_str] = legendflex(bars, legendData, 'FontSize', fontsize, ...
        'anchor', [2 2], 'buffer', [10 -20],'ncol',3);
    % apply hatch pattern to legends
    hatchfill2(object_h(3+2), 'single', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
    hatchfill2(object_h(3+3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
    grid on;
    title("SU Probing");
    ylabel("Time (s)");
    set(gca,'xticklabel', ["N = 32", "N = 256", "N = 1024"]);
    set(gca, 'FontSize', fontsize);
    set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
    set(gca,'ytick', 10.^[-6:2:2]);
    ylim([1e-4 1e2]);
    
    
    %%%%%%% 2. SU computational 
    fig2 = figure('Units','inches', 'Position', fig_size); 
    bars = bar(y8);
    set(gca,'YScale','log');
    for ii=1:3
        bars(ii).FaceColor = color(ii);
    end
    % apply hatch pattern to bars
    hatchfill2(bars(2), 'single', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
    hatchfill2(bars(3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
    legendData = {sysname, 'ACO', 'UbiG'};
    [legend_h, object_h, plot_h, text_str] = legendflex(bars, legendData, 'FontSize', fontsize, ...
        'anchor', [2 2], 'buffer', [10 -20],'ncol',3);
    % apply hatch pattern to legends
    hatchfill2(object_h(3+2), 'single', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
    hatchfill2(object_h(3+3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
    grid on;
    title("SU Computational");
    ylabel("Time (s)");
    set(gca,'xticklabel', ["N = 32", "N = 256", "N = 1024"]);
    set(gca, 'FontSize', fontsize);
    set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
    set(gca,'ytick', 10.^[-6:2:2]);
    ylim([1e-7 1e2]);
    

    %%%%%%% 3. SU overall 
    fig3 = figure('Units','inches', 'Position', fig_size); 
    bars = bar(y9);
    set(gca,'YScale','log');
    for ii=1:3
        bars(ii).FaceColor = color(ii);
    end
    % apply hatch pattern to bars
    hatchfill2(bars(2), 'single', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
    hatchfill2(bars(3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
    legendData = {sysname, 'ACO', 'UbiG'};
    [legend_h, object_h, plot_h, text_str] = legendflex(bars, legendData, 'FontSize', fontsize, ...
        'anchor', [2 2], 'buffer', [10 -20],'ncol',3);
    % apply hatch pattern to legends
    hatchfill2(object_h(3+2), 'single', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
    hatchfill2(object_h(3+3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');    
    grid on;
    title("SU Beam-training");
    ylabel("Time (s)");
    set(gca,'xticklabel', ["N = 32", "N = 256", "N = 1024"]);
    set(gca, 'FontSize', fontsize);
    set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
    set(gca,'ytick', 10.^[-6:2:2]);
    ylim([1e-4 1e2]);
    
    
    %%%%%%% 4. MU overall 
    fig4 = figure('Units','inches', 'Position', fig_size); 
    bars = bar(y13);
    set(gca,'YScale','log');
    for ii=1:3
        bars(ii).FaceColor = color(ii);
    end
    % apply hatch pattern to bars
    hatchfill2(bars(2), 'single', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
    hatchfill2(bars(3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20, 'HatchColor', 'black');
    legendData = {sysname, 'ACO', 'UbiG'};
    [legend_h, object_h, plot_h, text_str] = legendflex(bars, legendData, 'FontSize', fontsize, ...
        'anchor', [2 2], 'buffer', [10 -20],'ncol',3);
    % apply hatch pattern to legends
    hatchfill2(object_h(3+2), 'single', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');
    hatchfill2(object_h(3+3), 'cross', 'HatchAngle', 45, 'HatchDensity', 20/3, 'HatchColor', 'black');    
    grid on;
    title("MU Beam-training");
    ylabel("Time (s)");
    set(gca,'xticklabel', ["N = 32", "N = 256", "N = 1024"]);
    set(gca, 'FontSize', fontsize);
    set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
    set(gca,'ytick', 10.^[-6:2:2]);
    ylim([1e-4 2e2]);
end