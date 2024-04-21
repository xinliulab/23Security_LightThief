linestyles = ["-", "-.", "--", ":",'-',"-.","--", ":"]; 
fig_size = [1 1 12 6];
fontsize = 22;
export_fname = []; %["./figures/1.png"];

% slides 42, left figure, comparing SNR between different beamforming methods
load("d1.mat");
my_cdfplot(data.dp,"SNR (dB)",data.leg,linestyles,[],fontsize,fig_size,export_fname);

% slides 42, right figure, angle estimation
load("d2.mat");
my_cdfplot(abs(data.dp),"Angle Est. Error (deg)",data.leg,linestyles,[],fontsize,fig_size,export_fname);
