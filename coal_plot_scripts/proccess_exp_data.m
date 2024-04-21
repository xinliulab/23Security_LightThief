tic
NMEAS = 1000;
AZ = zeros(NMEAS, 1);
EL = zeros(NMEAS, 1);
SV = zeros(32, NMEAS);
for idx = [1:NMEAS]
    load(sprintf("D:/Lab computer/mmw-calibration-sim/exp_data/calibration/data%d.mat", idx));
    BPU = data.bpu;
    PA =  data.pa;
    
    PA.N_BEAM = 124;
    [H31, r31, SNR31, n31, BPU, PA, maxk_pos31, maxk_pks31]=debug_peaks(data.rx_aco_probes, BPU, PA);
    [rel_phase,rel_phase_avg,rel_phase_std] = get_rel_phase(r31);
    aco_activated_ant = [1:1+124/4];
    aco_sv = exp(1j*[0;-rel_phase_avg(aco_activated_ant(2:end)-1)]);
    sv = [aco_sv];
    legs = ["ACO"];
%     sv2beam(sv,[-90:1:90],[-50:1:50],PA,legs)

    az = [-60:1:60];
    el = [-10:1:10];
    sv2 = exp(-1j*2*pi/4.*sv2psh(sv./exp(1j*PA.PHASE_CAL)));
    pa = get_phased_array(PA.FREQ);
    [PAT_,AZ_ANG,EL_ANG] = pattern(pa,PA.FREQ,az,el,...
        'PropagationSpeed',physconst('LightSpeed'),'Type','power','Normalize',true,...
        'CoordinateSystem','polar','Weights',sv2);
  
%     figure; imagesc(AZ_ANG,EL_ANG,PAT_); colorbar; 
    [C,I] = max(PAT_(:));
    [I1,I2] = ind2sub(size(PAT_),I);
    fprintf("%d\t az=%d, el=%d\n",idx, az(I2), el(I1));

    AZ(idx) = az(I2);
    EL(idx) = el(I1);
    SV(:,idx) = sv;
end
toc

figure; histogram(AZ); mean(AZ(abs(EL)<=0))
figure; histogram(EL); mean(EL)

mean(AZ(abs(AZ)<=35))
figure(3); histogram(AZ(abs(AZ)<=35));
%%
close all;
A = zeros(32, 1000);
B = zeros(32, 1000);
for ii=1:1000
    A(:,ii) = conj(steervec(pa.getElementPosition()/(physconst('LightSpeed')/60.48e9), ...
        [AZ(ii); EL(ii)]));
    B(:,ii) = SV(:,ii)./(A(:,ii)./A(1,ii));
%     plot(angle(B)); hold on;
%     fprintf("az=%d, el=%d\n",AZ(ii), EL(ii));
end

az_idx_set1 = [4 12 10 1 2 11 13 15 7 5 9 16 14 23 21 26 32 30 17 18 27 29 31 20 28 25];
az_idx_set2 = [3 4  12 8 1 2  11 13 6 7 5 9  16 22 23 21 26 32 24 17 18 27 29 19 20 28];
el_idx_set1 = [6 22 24 1 7 23 17 19 2 5 21 18 20 11 9  26 27 28 13 16 32 29 25 14 30 31];
el_idx_set2 = [8 6  22 3 1 7  23 17 4 2 5  21 18 12 11 9  26 27 10 13 16 32 29 15 14 30];

% figure(1); 
% figure('Units','inches', 'Position', [1 1 15 5]);
% subplot(141); histogram(AZ(random_set)); title("AZ");
% subplot(142); histogram(EL(random_set)); title("EL");
% subplot(143); plot(angle(mean(A(az_idx_set1, random_set)./...
%     A(az_idx_set2,random_set),2)))
% subplot(144); plot(angle(mean(A(el_idx_set1, random_set)./...
%     A(el_idx_set2,random_set),2)))

rng(4);
good_idx = find(abs(EL)<=4 & abs(AZ)<=45); % size(good_idx)
new_idx = good_idx(randperm(length(good_idx))); %random_set;
% new_idx = good_idx;
n_points = [100:100:length(good_idx)];
az_err = zeros(26, length(n_points));
el_err = zeros(26, length(n_points));
for ii=1:length(n_points)
    random_set = new_idx([1:n_points(ii)]);
    az_err(:,ii) = angle(mean(A(az_idx_set1,random_set)./A(az_idx_set2,random_set),2));
    el_err(:,ii) = angle(mean(A(el_idx_set1, random_set)./A(el_idx_set2,random_set),2));

    C = SV(2:end, random_set)./SV(1:end-1, random_set);
    D = SV(az_idx_set1, random_set)./SV(az_idx_set2, random_set);
    D2 = SV(el_idx_set1, random_set)./SV(el_idx_set2, random_set);
    F = mean(D,2);
    F2 = mean(D2,2);
    Z2 = [1/F(5)/F(6)/F2(15)/F2(16) ...
    1/F(6)/F2(15)/F2(16) ...
    1/F(1)/F(2)/F2(14)/F2(15)/F2(16) ... %3
    1/F(2)/F2(14)/F2(15)/F2(16) ...
    1/F(11)/F2(16) ... %5
    1/F(9)/F(10)/F(11)/F2(16) ...
    1/F(10)/F(11)/F2(16) ...
    1/F(4)/F(5)/F(6)/F2(15)/F2(16) ...
    1/F2(16) ...
    F(17)/F2(19)/F2(20)/F2(21) ... %10
    1/F2(15)*F2(16) ...
    1/F2(14)/F2(15)*F2(16) ...
    F(17)/F2(20)/F2(21) ...
    F(17)*F(18)/F2(25)...
    F(17)*F(18)/F2(25)/F2(24) ... %15
    F(17)/F2(21)...
    F2(17)/F(20)/F(21)...
    F2(17)/F(21)...
    F2(17)*F2(18)/F(24)/F(25)... %19
    F2(17)*F2(18)/F(25)... %20
    1/F(16)...
    1/F(14)/F(15)/F(16)...
    1/F(15)/F(16)...
    F2(3)/F(14)/F(15)/F(16)... %24
    F(17)*F2(22)*F2(23) ...%25
    0 ...
    F2(17)...
    F2(17)*F2(18)...
    F2(17)*F(22)... %29
    F(17)*F(18)...
    F(17)*F(18)*F2(26)...
    F(17)].';

    cal_refant_26 = angle(Z2);
%     save(sprintf("newcal_%d.mat", n_points(ii)), "cal_refant_26");
end
figure('Units','inches', 'Position', [1 1 10 5]);
subplot(121); plot(n_points, abs(az_err(1,:)), 'bo-'); ylim([-0.05 0.7]); xlim([100 900]); xlabel("# measurements"); ylabel("Phase deviation in AZ direction (rad)"); 
hold on; plot([n_points(1) n_points(end)], [0 0], 'k--'); legend(["measured","expected"]);
subplot(122); plot(n_points, abs(el_err(1,:)), 'rs-'); ylim([-0.05 0.2]); xlim([100 900]); xlabel("# measurements"); ylabel("Phase deviation in EL direction (rad)");
hold on; plot([n_points(1) n_points(end)], [0 0], 'k--'); legend(["measured","expected"]);
%%
load("cal32_new_taoffice.mat"); 
PA.REFANT = 26; % 26 then 1
PA.PHASE_CAL(PA.ACTIVE_ANT) = angle(exp(1j*calibration_vec)./exp(1j*calibration_vec(PA.REFANT)));
PA_list = [PA];
for ii=[100:200:700]
    load(sprintf("newcal_%d.mat",ii));
    PA2 = PA; PA2.REFANT = 26;
    PA2.PHASE_CAL(PA.ACTIVE_ANT) = cal_refant_26;
    PA_list = [PA_list PA2];  
end

figure(4); 
for ii=2:length(PA_list)
    a = exp(1j.*(PA_list(ii).PHASE_CAL));
    b = exp(1j.*(PA_list(end).PHASE_CAL));
    p = plot(angle(a./b)); hold on;
    color = 'mckbrgymckbrgy';
    set(p, 'Color', color(ii));
    if ii>6
        set(p, 'LineStyle', '-.');
    end
end
legend(string([100:200:700]));

figure(5); 
ant_idx = [8 12 30];
tmp = zeros(4, length(ant_idx));
for ii=1:length(ant_idx)
    for jj=2:length(PA_list)
        tmp(jj-1,ii) = (PA_list(jj).PHASE_CAL(ant_idx(ii)));
    end
end
plot([100:200:700], tmp, 'o-');
legend("ant " + string(ant_idx));
xlabel("# samples");
ylabel("Phase calibration value (rad)");

% figure;viewArray(pa, "ShowIndex", "All", 'ShowNormals',true)
%% plot postcali
N = 16;
data_range = [11:26];
SNR_ACO = zeros(N,1);
SNR_11ad = zeros(N,1);
SNR_CS = zeros(N,3);
% SNR_CS_controlled = zeros(N,1);
% SNR_CS_uncontrolled_ref1 = zeros(N,1);
% SNR_CS_uncontrolled_ref26 = zeros(N,1);
ANG_ACO = zeros(N,2);
ANG_EX = zeros(N,3,2);
% ANG_EX_controlled = zeros(N,2);
% ANG_EX_uncontrolled_ref1 = zeros(N,2);
% ANG_EX_uncontrolled_ref26 = zeros(N,2);
ANG_CS = zeros(N,3,2);
% ANG_CS_controlled = zeros(N,2);
% ANG_CS_uncontrolled_ref1 = zeros(N,2);
% ANG_CS_uncontrolled_ref26 = zeros(N,2);

for ii = 1:length(data_range)
    idx = data_range(ii);
    load(sprintf("./exp_data/calibration/postcali/data%d.mat", idx));
    
    SNR_ACO(ii) = data.snr_aco;
    SNR_11ad(ii) = data.snr_11ad;
    SNR_CS(ii,:) = data.snr_cs_dominantpath;
%     SNR_CS_uncontrolled_ref1(ii) = data.snr_cs_dominantpath(2);
%     SNR_CS_uncontrolled_ref26(ii) = data.snr_cs_dominantpath(3);
    fprintf("[%d] snr: aco=%.1f, 11ad=%.1f, cs1=%.1f, cs2=%.1f, cs3=%.1f\n",...
        ii, SNR_ACO(ii),SNR_11ad(ii),SNR_CS(ii,:));
    

    BPU = data.bpu;
    PA_list =  data.pa;
    PA = PA_list(1);
    % ACO
    PA.N_BEAM = 124;
    [H31, r31, SNR31, n31, BPU, PA, maxk_pos31, maxk_pks31]=debug_peaks(data.rx_aco_probes, BPU, PA);
    [rel_phase,rel_phase_avg,rel_phase_std] = get_rel_phase(r31);
    aco_activated_ant = [1:1+124/4];
    v_aco = zeros(32,1);
    v_aco(setdiff(PA.ACTIVE_ANT, [PA.REFANT])) = exp(1j*[-rel_phase_avg]); 
    
    % CS search [controlled/uncontrolled]
    n = 124;
    v_dominantpath = zeros(32, 3);
    for jj=1:3
        PA = PA_list(jj);
        PA.N_BEAM = size(data.rx_cs_probes, 2);
        create_cs_codebook(n, PA);
        cb = "./codebooks/cs.mat";
        [H32, r32, SNR32, n32, BPU, PA, maxk_pos32, maxk_pks32]=debug_peaks(data.rx_cs_probes(:,:,jj), BPU, PA);
        [v_multipath_,v2_multipath_,v_dominantpath_,...
            path_ang,path_gain,unique_pos] = cs_multipath_algo(cb, ...
            BPU, PA, maxk_pos32(:,1:n), maxk_pks32(:,1:n), SNR32(1:n), ...
            r32(1:n), r32(1:n), 0);
        %             v_multipath(:,ii) = v_multipath_;
        %             v2_multipath(:,ii) = v2_multipath_;
        v_dominantpath(:,jj) = v_dominantpath_./v_dominantpath_(PA.REFANT).*exp(1j*PA.PHASE_CAL);
    end

    % exhaustive search [controlled/uncontrolled]
    PA.N_BEAM = size(data.rx_ex_probes, 2);
    for jj=1:3
        [H33, r33, SNR33, n33, BPU, PA, maxk_pos33, maxk_pks33]=debug_peaks(data.rx_ex_probes(:,:,jj), BPU, PA);
        [C,I] = max(SNR33);
        ANG_EX(ii, jj, 1) = data.az(I);
%         figure; plot(data.az, SNR33);
    end
    
    pa = get_phased_array(PA.FREQ);
    az = [-60:1:60];
    el = [-10:1:10];
    PA = PA_list(1);
    sv2 = exp(-1j*2*pi/4.*sv2psh(v_aco./exp(1j*PA.PHASE_CAL)));
    [PAT_,AZ_ANG,EL_ANG] = pattern(pa,PA.FREQ,az,el,...
        'PropagationSpeed',physconst('LightSpeed'),'Type','power','Normalize',true,...
        'CoordinateSystem','polar','Weights',sv2);
    [C,I] = max(PAT_(:));
    [I1,I2] = ind2sub(size(PAT_),I);
%     fprintf("max az=%d, el=%d\n",az(I2), el(I1));
    ANG_ACO(ii,:) = [az(I2) el(I1)];
    
    for jj=1:3
        PA = PA_list(jj);
        sv2 = exp(-1j*2*pi/4.*sv2psh(v_dominantpath(:,jj)./exp(1j*PA.PHASE_CAL)));
        [PAT_,AZ_ANG,EL_ANG] = pattern(pa,PA.FREQ,az,el,...
            'PropagationSpeed',physconst('LightSpeed'),'Type','power','Normalize',true,...
            'CoordinateSystem','polar','Weights',sv2);
        [C,I] = max(PAT_(:));
        [I1,I2] = ind2sub(size(PAT_),I);
        ANG_CS(ii,jj,:) = [az(I2) el(I1)];
%         figure; plot(data.az, SNR33);
    end
%     legs = ["ACO"];
%     sv2beam(sv,[-90:1:90],[-50:1:50],PA,legs)
    fprintf("    ang: aco=%.1f, ex1=%.1f, ex2=%.1f, ex3=%.1f, cs1=%.1f, cs2=%.1f, cs3=%.1f\n",...
        ANG_ACO(ii,1), ANG_EX(ii, :, 1), ANG_CS(ii,:,1));
end

% path(path, './plot_scripts');
linestyles = ["-", "-.", "--", ":",'-',"-.","--", ":"]; 
fig_size = [1 1 12 6];
fontsize = 22;
export_fname = []; %["./figures/1.png"];
% SNR 
p = [SNR_ACO SNR_11ad SNR_CS(:, [1 3])];
leg = ["ACO", "11ad", "SWIFT", "Ours"];
my_cdfplot(p,"SNR (dB)",leg,linestyles,[],fontsize,fig_size,export_fname);
% angle estimation 
% p = [ANG_EX(:,:,1) ANG_CS(:,:,1)] - ANG_ACO(:,1);
% leg = ["EX1","EX2","EX3","CS1","CS2","CS3"];
p = [ANG_CS(:,[1,3],1)] - ANG_ACO(:,1);
leg = ["SWIFT","Ours"];
my_cdfplot(abs(p),"Angle Est. Error (deg)",leg,linestyles,[],fontsize,fig_size,export_fname);

%% plot postcali2
N = 17;
data_range = [1:N];
SNR_ACO = zeros(N,1);
SNR_11ad = zeros(N,1);
SNR_CS = zeros(N,5);
ANG_ACO = zeros(N,2);
ANG_EX = zeros(N,5,2);
ANG_CS = zeros(N,5,2);

for ii = 1:length(data_range)
    idx = data_range(ii);
    load(sprintf("./exp_data/calibration/postcali2/data%d.mat", idx));
    
    SNR_ACO(ii) = data.snr_aco;
    SNR_11ad(ii) = data.snr_11ad;
    SNR_CS(ii,:) = data.snr_cs_dominantpath;
    fprintf("[%d] snr: aco=%.1f, 11ad=%.1f, cs(700 dp)=%.1f\n",...
        ii, SNR_ACO(ii),SNR_11ad(ii),SNR_CS(ii,end));
    

    BPU = data.bpu;
    PA_list =  data.pa;
    PA = PA_list(1);
    % ACO
    PA.N_BEAM = 124;
    [H31, r31, SNR31, n31, BPU, PA, maxk_pos31, maxk_pks31]=debug_peaks(data.rx_aco_probes, BPU, PA);
    [rel_phase,rel_phase_avg,rel_phase_std] = get_rel_phase(r31);
    aco_activated_ant = [1:1+124/4];
    v_aco = zeros(32,1);
    v_aco(setdiff(PA.ACTIVE_ANT, [PA.REFANT])) = exp(1j*[-rel_phase_avg]); 
    
    % CS search [controlled/uncontrolled]
    n = 124;
    v_dominantpath = zeros(32, 5);
    for jj=1:length(PA_list)
        PA = PA_list(jj);
        PA.N_BEAM = size(data.rx_cs_probes, 2);
        create_cs_codebook(n, PA);
        cb = "./codebooks/cs.mat";
        [H32, r32, SNR32, n32, BPU, PA, maxk_pos32, maxk_pks32]=debug_peaks(data.rx_cs_probes(:,:,jj), BPU, PA);
        [v_multipath_,v2_multipath_,v_dominantpath_,...
            path_ang,path_gain,unique_pos] = cs_multipath_algo(cb, ...
            BPU, PA, maxk_pos32(:,1:n), maxk_pks32(:,1:n), SNR32(1:n), ...
            r32(1:n), r32(1:n), 0);
        %             v_multipath(:,ii) = v_multipath_;
        %             v2_multipath(:,ii) = v2_multipath_;
        v_dominantpath(:,jj) = v_dominantpath_./v_dominantpath_(PA.REFANT).*exp(1j*PA.PHASE_CAL);
    end

    % exhaustive search [controlled/uncontrolled]
    PA.N_BEAM = size(data.rx_ex_probes, 2);
    for jj=1:length(PA_list)
        [H33, r33, SNR33, n33, BPU, PA, maxk_pos33, maxk_pks33]=debug_peaks(data.rx_ex_probes(:,:,jj), BPU, PA);
        [C,I] = max(SNR33);
        ANG_EX(ii, jj, 1) = data.az(I);
%         figure; plot(data.az, SNR33);
    end
    
    pa = get_phased_array(PA.FREQ);
    az = [-60:0.25:60];
    el = [-10:1:10];
    PA = PA_list(1);
    sv2 = exp(-1j*2*pi/4.*sv2psh(v_aco./exp(1j*PA.PHASE_CAL)));
    [PAT_,AZ_ANG,EL_ANG] = pattern(pa,PA.FREQ,az,el,...
        'PropagationSpeed',physconst('LightSpeed'),'Type','power','Normalize',true,...
        'CoordinateSystem','polar','Weights',sv2);
    [C,I] = max(PAT_(:));
    [I1,I2] = ind2sub(size(PAT_),I);
%     fprintf("max az=%d, el=%d\n",az(I2), el(I1));
    ANG_ACO(ii,:) = [az(I2) el(I1)];
    
    for jj=1:length(PA_list)
        PA = PA_list(jj);
        sv2 = exp(-1j*2*pi/4.*sv2psh(v_dominantpath(:,jj)./exp(1j*PA.PHASE_CAL)));
        [PAT_,AZ_ANG,EL_ANG] = pattern(pa,PA.FREQ,az,el,...
            'PropagationSpeed',physconst('LightSpeed'),'Type','power','Normalize',true,...
            'CoordinateSystem','polar','Weights',sv2);
        [C,I] = max(PAT_(:));
        [I1,I2] = ind2sub(size(PAT_),I);
        ANG_CS(ii,jj,:) = [az(I2) el(I1)];
%         figure; plot(data.az, SNR33);
    end
%     legs = ["ACO"];
%     sv2beam(sv,[-90:1:90],[-50:1:50],PA,legs)
    fprintf("    ang: aco=%.1f, ex=%.1f, cs=%.1f\n",...
        ANG_ACO(ii,1), ANG_EX(ii, end, 1), ANG_CS(ii,end,1));
end

path(path, './plot_scripts');
linestyles = ["-", "-.", "--", ":",'-',"-.","--", ":"]; 
fig_size = [1 1 12 6];
fontsize = 22;
export_fname = []; %["./figures/1.png"];
% SNR 
valid_idx = setdiff([1:N], []);
p = [SNR_ACO(valid_idx,1) SNR_11ad(valid_idx,1) SNR_CS(valid_idx, [1 5])];
leg = ["ACO", "11ad", "SWIFT", "Ours"];
my_cdfplot(p,"SNR (dB)",leg,linestyles,[],fontsize,fig_size,export_fname);
% compare SNR perf of difference calibration vectors
p = [SNR_CS(valid_idx, [1:5])];
leg = ["Controlled", "w/ 100 samples", "w/ 300 samples", "w/ 500 samples", "w/ 700 samples"];
my_cdfplot(p,"SNR (dB)",leg,linestyles,[],fontsize,fig_size,export_fname);
% angle estimation 
p = [ANG_CS(valid_idx,[1,5],1)] - ANG_ACO(valid_idx,1);
leg = ["SWIFT","Ours"];
my_cdfplot(abs(p),"Angle Est. Error (deg)",leg,linestyles,[],fontsize,fig_size,export_fname);
