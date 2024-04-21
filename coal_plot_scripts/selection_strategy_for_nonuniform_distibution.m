linestyles = ["-", "-.", "--", ":",'-',"-.","--", ":"]; 
fig_size = [1 1 12 6];
fontsize = 22;
export_fname = []; %["./figures/1.png"];

% slide 38
load("d8.mat");
figure('Units','inches', 'Position', [1 1 6 4]);
plot(100*[1:length(data.az_err)], abs(data.az_err), 'bo-'); 
hold on;
plot(100*[1:length(data.az_err2)], abs(data.az_err2), 'rs-'); 
% ylim([0 0.6]); xlim([100 100*length(data.az_err)]); 
xlabel("# measurements"); ylabel("angle of E[a(theta)] (rad)"); 
legend(["w/ shuffle (Ours)", "wo/ shuffle (Abhi)"]);