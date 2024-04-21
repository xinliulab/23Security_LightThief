linestyles = ["-", "-.", "--", ":",'-',"-.","--", ":"]; 
fig_size = [1 1 12 6];
fontsize = 22;
export_fname = []; %["./figures/1.png"];

% slide 41
% Show effectiveness of our calibration method. 
% Given a fixed beamforming method: Uncalibrated vs calibrated (controlled)
% vs calibrated (untrolled)
load("d5.mat");
my_cdfplot(data.dp,"SNR (dB)",data.leg,linestyles,[],fontsize,fig_size,export_fname);
