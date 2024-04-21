function [rx, H, rss_pwr, SNR, noise_pwr, BPU, PA, maxk_pos, maxk_pks] = measure_codebook(cb_name, BPU, PA)
    PA.TX_CB_NAME = cb_name;
    load(PA.TX_CB_NAME);
    cb_size = length(beam_weight);

    if cb_size <= 64
        PA.N_BEAM = cb_size;
        PA.TX_CB_ENTRIES = [zeros(1,PA.N_BEAM_WASTE) 0:PA.N_BEAM-1];
        PA.RX_CB_ENTRIES = zeros(1,length(PA.TX_CB_ENTRIES));
        [BPU, PA] = sanity_check(BPU, PA);
        run_cmd(sprintf("python ./M-Cube-Hostcmds/load_codebook.py %d 1 %d %s",PA.TX_IP,2^PA.TX_RF_MODULE,PA.TX_CB_NAME));
        run_cmd("sleep 0.1");
        [rx, H, rss_pwr, SNR, noise_pwr, BPU, PA, maxk_pos, maxk_pks] = get_measurement(BPU, PA, 0);
    else
        n = ceil(cb_size/64);
        rss_pwr = zeros(cb_size,1);
        noise_pwr = zeros(cb_size,1);
        SNR = zeros(cb_size,1);
        rx = zeros(BPU.PN_INTERVAL, cb_size);
        H = zeros(length(BPU.OFDM_PILOT_F),cb_size);
        maxk_pos = -99*ones(3,cb_size);
        maxk_pks = -99*ones(3,cb_size);
        cur_cb = beam_weight;
        for ii=1:n
            start_idx = 64*(ii-1) + 1;
            end_idx = min(64*(ii-1) + 64, cb_size);
            PA.N_BEAM = end_idx - start_idx + 1;
            cb_entry_to_write = [start_idx:end_idx];
            % write codebook
            beam_weight = cell(1,PA.N_BEAM);
            for jj=1:PA.N_BEAM
                beam_weight{jj} = cur_cb{cb_entry_to_write(jj)};
            end
            save("./codebooks/tmp.mat","beam_weight");

            % measure codebook
            PA.TX_CB_ENTRIES = [zeros(1,PA.N_BEAM_WASTE) 0:PA.N_BEAM-1];
            PA.RX_CB_ENTRIES = zeros(1,length(PA.TX_CB_ENTRIES));
            [BPU, PA] = sanity_check(BPU, PA);
            run_cmd(sprintf("python ./M-Cube-Hostcmds/load_codebook.py %d 1 %d %s",PA.TX_IP,2^PA.TX_RF_MODULE,"./codebooks/tmp.mat"));
            run_cmd("sleep 0.1");
            [rxx, Hhh, rrr, snrr, noise_pwrrr, BPU, PA, maxk_pos_, maxk_pks_] = get_measurement(BPU, PA, 0);
            rx(:,start_idx:end_idx) = rxx;
            H(:,start_idx:end_idx) = Hhh;
            rss_pwr(start_idx:end_idx) = rrr;
            SNR(start_idx:end_idx) = snrr;
            noise_pwr(start_idx:end_idx) = noise_pwrrr;
            maxk_pos(:,start_idx:end_idx) = maxk_pos_;
            maxk_pks(:,start_idx:end_idx) = maxk_pks_;
        end
    end
end