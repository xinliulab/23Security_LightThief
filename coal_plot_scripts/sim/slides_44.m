%% strategy for selecting samples to approximate uniform distribution
load("cal32_new_taoffice.mat"); % somhow this still works for node 1 mod 5
gnd_truth = (exp(1j.*calibration_vec)./exp(1j*calibration_vec(26))).';
% load("data2.mat");

rng('default') % For reproducibility
d = [];
base = 4000;
mu = 34; sigma = 13; r = random('Normal',mu,sigma,10*base, 1); d = [d; r];
% mu = 50; sigma = 6; r = random('Normal',mu,sigma,1000, 1); d = [d; r];
% mu = 40; sigma = 10; r = random('Uniform',-40,60,30000, 1); d = [d; r];
mu = -12; sigma = 8; r = random('Normal',mu,sigma,2*base, 1); d = [d; r];
mu = -41; sigma = 12; r = random('Normal',mu,sigma,4*base, 1); d = [d; r];
mu = 0; sigma = 10; r = random('Uniform',-60,60,5*base, 1); d = [d; r];
d = d(abs(d)<=60);
% histogram(d);

pa = get_phased_array(60.48e9);
A = conj(steervec(pa.getElementPosition()/(physconst('LightSpeed')/60.48e9), ...
        [d.'; zeros(1, length(d))]));

tmp_data = [];
tmp_data.az = d;
tmp_data.el = zeros(length(d),1);
tmp_data.sv = A.*gnd_truth;

ang = [-60:1:60];
cand_idx = -999*ones(length(ang), 1000);
steer = steervec(pa.getElementPosition()/(physconst('LightSpeed')/60.48e9), [ang;zeros(1,length(ang))]);

v = tmp_data.sv'*steer; 
[M, I] = max(v, [], 2);
for ii=1:length(ang)
%     cands = find(I==ii);
    cands = find(d==ang(ii));
    m = min(length(cands), size(cand_idx, 2));
    cand_idx(ii, 1:m ) = cands(1:m);
end

% figure; subplot(121); histogram(d, length(ang)); subplot(122); histogram(d(new_idx)); ang(exclude)
% exclude_origin = find(cand_idx(:,5)==-999);
[N,edges] = histcounts(d,length(ang));
[N2,edges2] = histcounts(ang(I),length(ang));

x = sum(ang(I)>=edges2(1:end-1).' & ang(I)<=edges2(2:end).' & (N2>5).', 1);
% [N3,edges3] = histcounts(d(find(x~=0)),edges2);
[N3,edges3] = histcounts(ang(I(find(x~=0))),edges2);


min_cnt = min(N2(N2>10));
y = ang(I);
new_idx = [];
for ii=1:length(N2)
    tmp = find(y>edges2(ii) & y<edges2(ii+1));
%     fprintf("%d, %d\n",ii,length(tmp));
    if length(tmp) >= min_cnt
        new_idx = [new_idx tmp(1:min_cnt)];
    end
end
% [N4,edges4] = histcounts(ang(I(new_idx)),edges2);
[N4,edges4] = histcounts(d(new_idx),edges2);
% fprintf("average az angle %.2f %.2f\n", mean(d), mean(d(new_idx)));
% 
% figure; subplot(131); plot(edges(1:end-1), N); 
% subplot(132); plot(edges2(1:end-1), N2);
% subplot(133); plot(edges4(1:end-1), N4);

rng(0);
[res,  az_err, el_err] = helper(tmp_data, randperm(length(d)), A);
[res2,  az_err2, el_err2] = helper(tmp_data, new_idx(randperm(length(new_idx))), A);
% size(new_idx)
% figure; plot(abs(az_err)); hold on; plot(abs(az_err2));

% figure; plot(rms(angle(res./gnd_truth), 1)); hold on; xlim([0 40])
% plot(rms(angle(res2./gnd_truth), 1)); hold on;

data = [];
data.ang = d;
data.cal_vec1 = res(:, 1:40);
data.cal_vec2 = res2(:, 1:40);
data.gnd_truth = gnd_truth;
% save("d6.mat", "data");
% load("d6.mat");
figure; 
subplot(121); 
histogram(data.ang); xlabel("Path angle (degree)"); ylabel("Count"); title("Unknown Distribution"); 
xlim([-60 60]); xticks(-60:30:60);
subplot(122);
plot([1:size(data.cal_vec1, 2)]*100, rms(angle(data.cal_vec1./data.gnd_truth), 1)); hold on;
plot([1:size(data.cal_vec2, 2)]*100, rms(angle(data.cal_vec2./data.gnd_truth), 1)); hold on;
xlim([0 size(data.cal_vec2, 2)*100]); legend(["wo/ selection strategy", "w/ selection strategy"]);
xlabel("Number of measurements"); ylabel("RMS phase error (rad)");