linestyles = ["-", "-.", "--", ":",'-',"-.","--", ":"]; 
fig_size = [1 1 12 6];
fontsize = 22;
export_fname = []; %["./figures/1.png"];
% slides 39, right figure, convergence of calibration vector
load("d4.mat");
figure;
for ii=1:32
    subplot(6,6,ii);
    plot([100:200:700], data.dp(:,ii), 'o-');
    xticks([100:200:700]);
    title("ant " + string(ii));
    xlabel("# samples");
    ylabel("calibration (rad)");
end