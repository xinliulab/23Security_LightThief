function [] = HelperPlotBeamPatternsExpData(v_set, Params, leg)    
    Angles=[-90:90];
    SteerVectors = steervec(Params.PhasedArray.getElementPosition()/Params.Lambda, [Angles; zeros(1, length(Angles))]);
    BeamPatterns = db(v_set'*SteerVectors);
    
    fontsize = 18;
    fig_size = [1 1 6 4];
    linewidth = 2.5;
    markersz = 8;
    color1 = 'mkc';
    color2 = 'brg';
    style = '-:.';
    fig = figure('Units','inches', 'Position', fig_size);
    for ii=1:size(BeamPatterns,1)
        polarplot(deg2rad(Angles), BeamPatterns(ii,:)-max(BeamPatterns(ii,:)), [color1(ii) style(ii)], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
    end
    PathAngles = [-6, -39];
    for ii=1:length(PathAngles)
        polarplot(deg2rad(PathAngles(ii))*ones(1,2), [-35 0], [color2(ii) '--'], 'LineWidth', linewidth, "MarkerSize", markersz);hold on;
        leg = [leg sprintf("Path%d", ii)];
    end
    ax = gca;
    ax.ThetaDir = 'clockwise';
    set(gca, 'ThetaZeroLocation', 'top', 'FontSize', fontsize);
    set(gca, 'fontsize', fontsize);
    thetalim([-90 90]);
    rlim([-30 0]);
    legend(leg, 'Location', 'northoutside', 'NumColumns',2, 'Fontsize',fontsize);
end