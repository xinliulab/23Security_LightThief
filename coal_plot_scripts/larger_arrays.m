linestyles = ["-", "-.", "--", ":",'-',"-.","--", ":"]; 
fig_size = [1 1 12 6];
fontsize = 22;
export_fname = []; %["./figures/1.png"];

% slide 43, Simulate larger arrays.
load("d7.mat");
fig = figure('Units','inches', 'Position', [1 1 10 4]);
bar(data.mean_err); legend("array size "+string(data.URA_size));
set(gca, 'XTickLabel', string(data.Nmeas))
xlabel("Number of measurements"); ylabel("RMS estimation error (rad)");