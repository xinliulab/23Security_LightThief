function [data] = ftp_micro_benchmark(idx,az,aco_cbsize,savedata,save_folder,BPU,PA)
    tic
    close all;
    % repeat = 10;
    data = [];
    % data.rx_cs_probes        = zeros(1055760, length(aco_cbsize));
    data.az                  = az;
    data.rx_ex_probes        = zeros(BPU.PN_INTERVAL, length(data.az));
    data.rx_aco_probes       = zeros(BPU.PN_INTERVAL, 124);
    data.rx_aco_amp_probes   = zeros(BPU.PN_INTERVAL, 32);
    data.rx_cs_probes        = zeros(BPU.PN_INTERVAL, 124);
    data.vary_phase          = pi*[0:10]/10; % rad
    data.snr_vary_phase      = zeros(length(data.vary_phase), 1);
    data.snr_aco             = zeros(length(aco_cbsize), 1);

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
    
    % ACO amp probes
    beam_weight = cell(1,32);
    for ii=1:32
        mag = zeros(32,1);
        mag(ii) = 7;
        psh = zeros(32,1);
        beam_weight{ii} = {int2str(mag), int2str(psh), int2str(6*ones(8,1))};
    end
    save("./codebooks/tmp.mat","beam_weight");
    cb = "./codebooks/tmp.mat";
    [rx9, H9, r9, SNR9, n9, BPU, PA, maxk_pos9, maxk_pks9] = measure_codebook(cb, BPU, PA);
    data.rx_aco_amp_probes = rx9;

    % CS probes
    create_cs_codebook(124, PA);
    cb = "./codebooks/cs.mat";
    [rx1, H1, r1, SNR1, n1, BPU, PA, maxk_pos1, maxk_pks1] = measure_codebook(cb, BPU, PA);
    data.rx_cs_probes = rx1;
 
%     v_multipath    = zeros(length(PA.ACTIVE_ANT),length(data.vary_phase));
%     v_aco          = zeros(length(PA.ACTIVE_ANT),length(aco_cbsize));
    % calculate CS beams
%     n = aco_cbsize(end);
%     create_cs_codebook(n, PA);
%     cb = "./codebooks/cs.mat";
%     [v_multipath_,v2_multipath_,v_dominantpath_,...
%         path_ang,path_gain,unique_pos] = cs_multipath_algo(cb, ...
%         BPU, PA, maxk_pos1(:,1:n), maxk_pks1(:,1:n), SNR1(1:n), ...
%         rx1(:,1:n), r1(1:n), 0);
    
%     tmp4 = zeros(length(PA.ACTIVE_ANT),length(data.vary_phase));
%     pa = get_phased_array(PA.FREQ);
%     assert(length(unique_pos)==2);
%     for ii=1:length(unique_pos)
%         if ii==1
%             a = conj(path_gain(ii))*steervec(pa.getElementPosition()/PA.LAM, path_ang(:,ii));
%             tmp4 = tmp4 + repmat(a,1,length(data.vary_phase));
%         else
%             tmp4 = tmp4 + exp(1j*data.vary_phase).*conj(path_gain(ii)).*steervec(pa.getElementPosition()/PA.LAM, path_ang(:,ii));
%         end
%     end
%     v_multipath = tmp4;

%     % calculate ACO beams
%     aco_activated_ant = [1:1+n/4];
%     v_aco(aco_activated_ant,ii) = exp(1j*[0;-rel_phase_avg(aco_activated_ant(2:end)-1)]);

    
    % measure the performance for each BF scheme
%     v2 = v_multipath./v_multipath(1,:).*exp(1j*PA.PHASE_CAL);
%     v3 = v_dominantpath./v_dominantpath(1,:).*exp(1j*PA.PHASE_CAL);
%     v4 = v2_multipath./v2_multipath(1,:).*exp(1j*PA.PHASE_CAL);
%     v5 = v_aco;
%     v6 = get_sv_from_default_codebook(v_11ad_idx);
%     sv = [v2];
%     cb = "./codebooks/tmp2.mat";
%     sv2codebook(cb, sv);
%     [rx2, H2, r2, SNR2, n2, BPU, PA, maxk_pos2, maxk_pks2] = measure_cs_multipath_codebook(cb, BPU, PA);
    
%     data.snr_vary_phase    = SNR2;
%     data.snr_cs_dominantpath = SNR2(1*length(aco_cbsize)+[1:length(aco_cbsize)]);
%     data.snr_cs_multipath_v2 = SNR2(2*length(aco_cbsize)+[1:length(aco_cbsize)]);
%     data.snr_aco             = SNR2(3*length(aco_cbsize)+[1:length(aco_cbsize)]);
%     data.snr_11ad            = SNR2(4*length(aco_cbsize)+[1:length(aco_cbsize)]);
    
%     Hrx = [0;rel_phase_avg].';
%     snr_db = db(Hrx*v_multipath);
%     fig = figure; 
%     plot(data.vary_phase/pi, snr_db, 'LineWidth',2); hold on;
%     xlabel("Phase error (in pi)"); ylabel("SNR (dB)");

    % figure; plot(10*log10([r2 r3 r5]));
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
%         exportgraphics(fig,sprintf("%s/data%d.png",save_folder, idx),'Resolution',600);
        save(sprintf("%s/data%d.mat",save_folder, idx), "data");
    end
    toc
    % legs = ["SWIFT2.0","CS", "SWIFT2.0 v2", "ACO","11ad"];
    % sv2beam(sv(:,length(aco_cbsize):length(aco_cbsize):end),[-90:3:90],[-50:2:50],PA,legs)
end