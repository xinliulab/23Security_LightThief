load("data2.mat");
pa = get_phased_array(60.48e9);

A = zeros(32, 1000);
for ii=1:1000
    A(:,ii) = conj(steervec(pa.getElementPosition()/(physconst('LightSpeed')/60.48e9), ...
        [data2.az(ii); data2.el(ii)]));
end

rng(4);
good_idx = find(abs(data2.el)<=3 & abs(data2.az)<=35); % size(good_idx)
new_idx = good_idx(randperm(length(good_idx))); %random_set;
abhi_idx = find(abs(data2.el)<=4 & abs(data2.az)<=45); %[1:length(new_idx)];

[res,az_err,el_err] = helper(data2, new_idx, A);
[res2,az_err2,el_err2] = helper(data2, abhi_idx, A);

data = [];
data.az_err = az_err;
data.az_err2 = az_err2;
% save("../d8.mat", "data");
close all;
figure('Units','inches', 'Position', [1 1 10 5]);
plot(100*[1:length(data.az_err)], abs(data.az_err), 'bo-'); 
hold on;
plot(100*[1:length(data.az_err2)], abs(data.az_err2), 'rs-'); 
% ylim([0 0.6]); xlim([100 100*length(data.az_err)]); 
xlabel("# measurements"); ylabel("angle of E[a(theta)] (rad)"); 
legend(["w/ shuffle (Ours)", "wo/ shuffle (Abhi)"]);