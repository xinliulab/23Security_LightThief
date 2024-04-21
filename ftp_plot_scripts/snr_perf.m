% close all;
leg=["FTP", "ACO", "11ad"]; 
linestyles = ["-", "-.", "--", ":",'-']; 
fig_size = [1 1 6 4];
fontsize = 22;

% 9a
export_fname = "../figures/los_snr_cdf.pdf";
load("./fig9a.mat");
my_cdfplot(p,"SNR (dB)",leg,linestyles,[],fontsize,fig_size,export_fname);

% 9b
export_fname = "../figures/los_tpt_cdf.pdf";
load("./fig9b.mat");
my_cdfplot(p./1e6,"Throughput (Mbps)",leg,linestyles,[],fontsize,fig_size,export_fname);

% 9c
export_fname = "../figures/nlos_snr_cdf.pdf";
load("./fig9c.mat");
my_cdfplot(p,"SNR (dB)",leg,linestyles,[],fontsize,fig_size,export_fname);

% 9d
export_fname = "../figures/nlos_tpt_cdf.pdf";
load("./fig9d.mat");
my_cdfplot(p./1e6,"Throughput (Mbps)",leg,linestyles,[],fontsize,fig_size,export_fname);