function [data] = coal_calibration(idx,az,aco_cbsize,savedata,save_folder,BPU,PA)
    tic
    close all;
    % repeat = 10;
    data = [];
    % data.rx_cs_probes        = zeros(1055760, length(aco_cbsize));
    data.az                  = az;
    data.rx_ex_probes        = zeros(BPU.PN_INTERVAL, length(data.az));
    data.rx_aco_probes       = zeros(BPU.PN_INTERVAL, 124);
    data.rx_cs_probes        = zeros(BPU.PN_INTERVAL, 124);
%     data.rx_11ad_probes      = zeros(BPU.PN_INTERVAL, 124);
%     data.rx_cs_multipath     = zeros(BPU.PN_INTERVAL, length(aco_cbsize));
    % data.rx_cs_multipath_v2  = zeros(BPU.PN_INTERVAL, 124, length(aco_cbsize));
    % data.rx_cs_dominantpath  = zeros(BPU.PN_INTERVAL, 124, length(aco_cbsize));
    data.rx_aco              = zeros(BPU.PN_INTERVAL, length(aco_cbsize));
    % data.rx_11ad             = zeros(BPU.PN_INTERVAL, 124, length(aco_cbsize));
%     data.snr_cs_multipath    = zeros(length(aco_cbsize), 1);
%     data.snr_cs_multipath_v2 = zeros(length(aco_cbsize), 1);
%     data.snr_cs_dominantpath = zeros(length(aco_cbsize), 1);
%     data.snr_aco             = zeros(length(aco_cbsize), 1);
%     data.snr_11ad            = zeros(length(aco_cbsize), 1);
%     data.tpt_cs_multipath    = zeros(length(aco_cbsize), 1);
%     data.tpt_cs_multipath_v2 = zeros(length(aco_cbsize), 1);
%     data.tpt_cs_dominantpath = zeros(length(aco_cbsize), 1);
%     data.tpt_aco             = zeros(length(aco_cbsize), 1);
%     data.tpt_11ad            = zeros(length(aco_cbsize), 1);
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
    
%     % 11ad probes
%     create_default_codebook(124, PA);
%     cb = "./codebooks/default.mat";
%     [rx6, H6, r6, SNR6, n6, BPU, PA, maxk_pos6, maxk_pks6] = measure_cs_multipath_codebook(cb, BPU, PA);
%     data.rx_11ad_probes = rx6;
     
    if savedata == 1
        mkdir(save_folder);
%         exportgraphics(fig,sprintf("%s/data%d.png",save_folder, idx),'Resolution',600);
        save(sprintf("%s/data%d.mat",save_folder, idx), "data");
    end
    toc
    % legs = ["SWIFT2.0","CS", "SWIFT2.0 v2", "ACO","11ad"];
    % sv2beam(sv(:,length(aco_cbsize):length(aco_cbsize):end),[-90:3:90],[-50:2:50],PA,legs)
end