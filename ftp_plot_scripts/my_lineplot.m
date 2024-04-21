function [fig] = my_lineplot(x, plotdata,xlabel_,ylabel_,legend_,fontsize,export_fname)
%     fontsize = 13;
    color = 'brgmcrgbrkymcrgbrkymc';
    markers = {'o';'^';'*';'s';'+';'d';'x';'p'};
    fig = figure('DefaultAxesFontSize', fontsize, 'Position', [100 100 200*3 200*2]); 
    for ii=1:size(plotdata,2)
        h = plot(1:length(x), plotdata(:,ii),"LineWidth", 2.0, "MarkerSize", 8); hold on;
        set(h,{'Marker'}, markers(ii));
        set(h, 'Color', color(ii));
    end
    xticks(1:length(x));
    xticklabels(x);
    grid on;
%     ylim([0.1 0.85]);
    legend(legend_, "Location", "best", "FontSize", fontsize);
    ylabel(ylabel_);
    xlabel(xlabel_);
    if ~isempty(export_fname)
        exportgraphics(fig,export_fname,'Resolution',300);
    end
end