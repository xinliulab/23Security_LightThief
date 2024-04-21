linestyles = ["-", "-.", "--", ":",'-',"-.","--", ":"]; 
fig_size = [1 1 12 6];
fontsize = 22;
export_fname = []; %["./figures/1.png"];

% slide 36, choosing reference antenna wisely can reduce the RMS phase estimation error
load("d7.mat");
fig = figure('Units','inches', 'Position', [1 1 10 4]);
bar([data.mean_err(end,:).' data.mean_err2(end,:).']); legend(["ref in the middle", "ref in the corner"]);
set(gca, 'XTickLabel', string(data.URA_size))
xlabel("Phased array size"); ylabel("RMS estimation error (rad)");