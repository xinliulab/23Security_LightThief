function [data] = ftp_exp(idx,az,aco_cbsize,savedata,save_folder,BPU,PA)
    tic
    close all;
    % repeat = 10;
    data = [];
    % data.rx_cs_probes        = zeros(1055760, length(aco_cbsize));
    data.az                  = az;
    data.rx_ex_probes        = zeros(BPU.PN_INTERVAL, length(data.az));
    data.rx_aco_probes       = zeros(BPU.PN_INTERVAL, 124);
    data.rx_cs_probes        = zeros(BPU.PN_INTERVAL, 124);
    data.rx_11ad_probes      = zeros(BPU.PN_INTERVAL, 124);
    data.rx_cs_multipath     = zeros(BPU.PN_INTERVAL, length(aco_cbsize));
    % data.rx_cs_multipath_v2  = zeros(BPU.PN_INTERVAL, 124, length(aco_cbsize));
    % data.rx_cs_dominantpath  = zeros(BPU.PN_INTERVAL, 124, length(aco_cbsize));
    data.rx_aco              = zeros(BPU.PN_INTERVAL, length(aco_cbsize));
    % data.rx_11ad             = zeros(BPU.PN_INTERVAL, 124, length(aco_cbsize));
    data.snr_cs_multipath    = zeros(length(aco_cbsize), 1);
    data.snr_cs_multipath_v2 = zeros(length(aco_cbsize), 1);
    data.snr_cs_dominantpath = zeros(length(aco_cbsize), 1);
    data.snr_aco             = zeros(length(aco_cbsize), 1);
    data.snr_11ad            = zeros(length(aco_cbsize), 1);
    data.tpt_cs_multipath    = zeros(length(aco_cbsize), 1);
    data.tpt_cs_multipath_v2 = zeros(length(aco_cbsize), 1);
    data.tpt_cs_dominantpath = zeros(length(aco_cbsize), 1);
    data.tpt_aco             = zeros(length(aco_cbsize), 1);
    data.tpt_11ad            = zeros(length(aco_cbsize), 1);
    data.aco_cbsize          = aco_cbsize;
    data.bpu                 = BPU;
    data.pa                  = PA;
    
%     debug_pwr_cs_multipath   = zeros(repeat, length(aco_cbsize));
%     debug_pwr_cs_dominantpath= zeros(repeat, length(aco_cbsize));
%     debug_pwr_aco            = zeros(repeat, length(aco_cbsize));
%     debug_pwr_11ad           = zeros(repeat, length(aco_cbsize));
%     debug_path_ang           = zeros(2, length(aco_cbsize));
    
    % Exhaustive search
    create_exhaustive_codebook(data.az,[0],1,PA);
    cb = "./codebooks/exhaustive_cal.mat"; 
    [rx97, H97, r97, SNR97, n97, BPU, PA, maxk_pos97, maxk_pks97] = measure_codebook(cb, BPU, PA);
    data.rx_ex_probes = rx97;
    
    % ACO probes
    create_csi_codebook(124, 1, PA.ACTIVE_ANT(2:32), PA);
    cb = "./codebooks/csi.mat";
    [rx4, H4, r4, SNR4, n4, BPU, PA, maxk_pos4, maxk_pks4] = measure_codebook(cb, BPU, PA);
    data.rx_aco_probes = rx4;
    [rel_phase,rel_phase_avg,rel_phase_std] = get_rel_phase(r4);
    
    % CS probes
    create_cs_codebook(124, PA);
    cb = "./codebooks/cs.mat";
    [rx1, H1, r1, SNR1, n1, BPU, PA, maxk_pos1, maxk_pks1] = measure_codebook(cb, BPU, PA);
    data.rx_cs_probes = rx1;
    if BPU.DO_OFDM == 1
        [maxk_pos11, maxk_pks11] = super_resolution(H1,0);
    else
        maxk_pos11 = maxk_pos1;
        maxk_pks11 = maxk_pks1;
    end
    
    % 11ad probes
    create_default_codebook(124, PA);
    cb = "./codebooks/default.mat";
    [rx6, H6, r6, SNR6, n6, BPU, PA, maxk_pos6, maxk_pks6] = measure_codebook(cb, BPU, PA);
    data.rx_11ad_probes = rx6;
    
    v_multipath    = zeros(length(PA.ACTIVE_ANT),length(aco_cbsize));
    v2_multipath   = zeros(length(PA.ACTIVE_ANT),length(aco_cbsize));
    v_dominantpath = zeros(length(PA.ACTIVE_ANT),length(aco_cbsize));
    v_aco          = zeros(length(PA.ACTIVE_ANT),length(aco_cbsize));
    v_11ad_idx     = zeros(length(aco_cbsize),1);
    for ii=1:length(aco_cbsize)
        % calculate CS beams
        n = aco_cbsize(ii);
        create_cs_codebook(n, PA);
        cb = "./codebooks/cs.mat";
        [v_multipath_,v2_multipath_,v_dominantpath_,...
            path_ang,path_gain,unique_pos] = ftp_algo(cb, ...
            BPU, PA, maxk_pos11(:,1:n), maxk_pks11(:,1:n), SNR1(1:n), ...
            rx1(:,1:n), r1(1:n), 0);
        v_multipath(:,ii) = v_multipath_;
        v2_multipath(:,ii) = v2_multipath_;
        v_dominantpath(:,ii) = v_dominantpath_;
        % calculate ACO beams
        aco_activated_ant = [1:1+n/4];
        v_aco(aco_activated_ant,ii) = exp(1j*[0;-rel_phase_avg(aco_activated_ant(2:end)-1)]); 
        % choose the best 11ad beams
        [M6, I6] = max(SNR6(1:n)); 
        v_11ad_idx(ii) = I6;
    end
    
    % measure the performance for each BF scheme
    v2 = v_multipath./v_multipath(1,:).*exp(1j*PA.PHASE_CAL);
    v3 = v_dominantpath./v_dominantpath(1,:).*exp(1j*PA.PHASE_CAL);
    v4 = v2_multipath./v2_multipath(1,:).*exp(1j*PA.PHASE_CAL);
    v5 = v_aco;
    v6 = get_sv_from_default_codebook(v_11ad_idx);
    sv = [v2 v3 v4 v5 v6];
    cb = "./codebooks/tmp2.mat";
    sv2codebook(cb, sv);
    [rx2, H2, r2, SNR2, n2, BPU, PA, maxk_pos2, maxk_pks2] = measure_codebook(cb, BPU, PA);
    
    data.snr_cs_multipath    = SNR2(0*length(aco_cbsize)+[1:length(aco_cbsize)]);
    data.snr_cs_dominantpath = SNR2(1*length(aco_cbsize)+[1:length(aco_cbsize)]);
    data.snr_cs_multipath_v2 = SNR2(2*length(aco_cbsize)+[1:length(aco_cbsize)]);
    data.snr_aco             = SNR2(3*length(aco_cbsize)+[1:length(aco_cbsize)]);
    data.snr_11ad            = SNR2(4*length(aco_cbsize)+[1:length(aco_cbsize)]);
    
    if BPU.DO_OFDM==1
        data.rx_cs_multipath = rx2(:,0*length(aco_cbsize)+[1:length(aco_cbsize)]);
        data.rx_aco = rx2(:,3*length(aco_cbsize)+[1:length(aco_cbsize)]);
    end

    % cb = "./codebooks/tmp3.mat";
    % sv2codebook(cb, sv(:,length(aco_cbsize):length(aco_cbsize):end));
    % [out, PA] = measure_11ad_per(cb, BPU, PA);
    % rate_11ad = 1e6*[385,770,962.5,1155,1251.3,1540,1925,2310,2502.5,3080,3850,4620].';
    % tpt = max((1-out.PER).*rate_11ad/(1760e6/BPU.FS));
    
    data.tpt_cs_multipath    = BPU.FS*log2(1+db2pow(data.snr_cs_multipath));
    data.tpt_cs_dominantpath = BPU.FS*log2(1+db2pow(data.snr_cs_dominantpath));
    data.tpt_cs_multipath_v2 = BPU.FS*log2(1+db2pow(data.snr_cs_multipath_v2));
    data.tpt_aco             = BPU.FS*log2(1+db2pow(data.snr_aco));
    data.tpt_11ad            = BPU.FS*log2(1+db2pow(data.snr_11ad));
    
    %     plot_codebook(cb,[-60:2:60],[-30:2:30],PA);
    %     beam_weight = [mat2cell(repmat(entry2,repeat,1),ones(1,repeat)).' ...
    %                    mat2cell(repmat(entry3,repeat,1),ones(1,repeat)).' ...
    %                    mat2cell(repmat(entry5,repeat,1),ones(1,repeat)).'...
    %                    mat2cell(repmat(entry6,repeat,1),ones(1,repeat)).'];
    %     save("./codebooks/tmp7.mat","beam_weight");
    %     cb = "./codebooks/tmp7.mat";
    % %     [rx7, r7, SNR7, n7, BPU, PA] = measure_codebook(cb, BPU, PA);
    %     [rx7, H7, r7, SNR7, n7, BPU, PA, maxk_pos7, maxk_pks7] = measure_cs_multipath_codebook(cb, BPU, PA);
    %     figure(102); plot(reshape(db(r7,'power'),repeat,[])); legend(["SWIFT2.0", "SWIFT1.0", "ACO","11ad"]);
    
    
%     % figure; plot(10*log10([r2 r3 r5]));
%     fig = figure('Position', [100 100 200*8 200*4]);
%     subplot(2,2,1); plot(SNR4); title("ACO probe SNR");
%     subplot(2,2,2); plot(SNR1); title("CS probe SNR");
%     subplot(2,2,3); plot(aco_cbsize,[data.snr_cs_multipath ...
%             data.snr_cs_dominantpath data.snr_aco ...
%             data.snr_cs_multipath_v2 data.snr_11ad]); 
%     xlabel("# measurements"); ylabel("SNR (dB)");
%     legend(["SWIFT2.0", "CS", "ACO", "SWIFT2.0 v2", "11ad"]);
%     subplot(2,2,4); 
%     plot(aco_cbsize, [data.tpt_cs_multipath ...
%             data.tpt_cs_dominantpath data.tpt_aco ...
%             data.tpt_cs_multipath_v2 data.tpt_11ad]/1e6);
%     % set(gca,'xticklabel',["SWIFT2.0", "CS", "ACO", "SWIFT2.0 v2", "11ad"]);
%     xlabel("# measurements"); ylabel("Throughput (Mbps)");
%     % title(sprintf("cs angle: %s",num2str(path_ang(1,:))));
    
    % fprintf("SWIFT2.0\tSWIFT2.0v2\tCS\tACO\t11ad\n");
    % fprintf("%.1f\t%.1f\t%.1f\t%.1f\t%.1f\n",...
    %     mean(data.snr_cs_multipath), mean(data.snr_cs_multipath_v2),...
    %     mean(data.snr_cs_dominantpath), mean(data.snr_aco), ...
    %     mean(data.snr_11ad));
    
    if savedata == 1
        mkdir(save_folder);
        exportgraphics(fig,sprintf("%s/data%d.png",save_folder, idx),'Resolution',600);
        save(sprintf("%s/data%d.mat",save_folder, idx), "data");
    end
    toc
    % legs = ["SWIFT2.0","CS", "SWIFT2.0 v2", "ACO","11ad"];
    % sv2beam(sv(:,length(aco_cbsize):length(aco_cbsize):end),[-90:3:90],[-50:2:50],PA,legs)
end