linestyles = ["-", "-.", "--", ":",'-',"-.","--", ":"]; 
fig_size = [1 1 12 6];
fontsize = 22;
export_fname = []; %["./figures/1.png"];
% slides 40, left figure, comparing SNR between controlled vs uncontrolled calibration
load("d3.mat");
my_cdfplot(data.dp,"SNR (dB)",data.leg,linestyles,[],fontsize,fig_size,export_fname);
