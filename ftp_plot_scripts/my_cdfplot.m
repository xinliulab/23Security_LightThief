function [fig] = my_cdfplot(plotdata,xlabel_,legend_,linestyle_,xlim_,fontsize, fig_size, export_fname)
%     fontsize = 13;
%     fig = figure('DefaultAxesFontSize', fontsize, 'Position', [100 100 200*3 200*2]); 
    fig = figure('Units','inches', 'Position', fig_size);
%     color = 'rbgmcrgbrkymcrgbrkymc';
    color = 'mckbrgbrkymcrgbrkymc';
    for ii=1:size(plotdata,2)
        [h1, stats1]= cdfplot(plotdata(:,ii)); hold on;
        set(h1 ,'LineWidth',3 , 'LineStyle', '-');
        set(h1, 'Color', color(ii));
        if ~isempty(linestyle_)
            set(h1, 'LineStyle', linestyle_(ii));
        end
        if ~isempty(legend_)
            fprintf("%s, median: %.2f\n",legend_(ii),stats1.median);
        end
    end
    set(gca, 'FontSize', fontsize);
    set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');

    xlabel(xlabel_);
    ylabel("CDF");
    title("");
    if ~isempty(xlim_)
        xlim(xlim_);
    end
    if ~isempty(legend_)
        legend(legend_, 'Location','best',"FontSize", fontsize);
    end
    if ~isempty(export_fname)
        exportgraphics(fig,export_fname,'Resolution',300);
    end
end