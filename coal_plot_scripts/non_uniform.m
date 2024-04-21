linestyles = ["-", "-.", "--", ":",'-',"-.","--", ":"]; 
fig_size = [1 1 12 6];
fontsize = 22;
export_fname = []; %["./figures/1.png"];

% slide 44
% Show that we can deal with non-uniform angle distribution. This is from simulation. 
% First, we assume that ACO can be utilized to obtain the per-antenna CSI, which in turn can 
% be used to infer the path angle by correlating it against beamforming vectors for different directions. 
% As a result, we have the correlation map, wo/ phase offsets (left) and w/ phase offsets (right). 
load("d6_2.mat");
fig=figure;
subplot(121); tmp = abs(data.steer'*data.steer).'; imagesc([data.ang(1) data.ang(end)],[data.ang(1) data.ang(end)],tmp./max(tmp)); colorbar;
subplot(122); tmp = abs(data.new_steer'*data.steer).'; imagesc([data.ang(1) data.ang(end)],[data.ang(1) data.ang(end)],tmp./max(tmp)); colorbar;
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
han.XLabel.Visible='on';
han.YLabel.Visible='on';
ylabel(han,"ground truth angle");
xlabel(han,"Estimated angle");
% With a non-uniform distribution, increasing the number of measurements
% does not increase accuracy. We have a heuristic to select samples such
% that it approximates uniform distribution. 
load("d6.mat");
figure; 
subplot(121); 
histogram(data.ang); xlabel("Path angle (degree)"); ylabel("Count"); title("Unknown Distribution"); 
xlim([-60 60]); xticks(-60:30:60);
subplot(122);
plot([1:size(data.cal_vec1, 2)]*100, rms(angle(data.cal_vec1./data.gnd_truth), 1)); hold on;
plot([1:size(data.cal_vec2, 2)]*100, rms(angle(data.cal_vec2./data.gnd_truth), 1)); hold on;
xlim([0 size(data.cal_vec2, 2)*100]); legend(["wo/ selection strategy", "w/ selection strategy"]);
xlabel("Number of measurements"); ylabel("RMS phase error (rad)");