function [rx_segments, H, rss_pwr, SNR, noise_pwr, BPU, PA, maxk_pos, maxk_pks] = get_cs_multipath_measurement(BPU, PA, DEBUG)
    if nargin < 3 || DEBUG==0
        DEBUG = 0;
    end
    rx_segments = zeros(BPU.PN_INTERVAL, PA.N_BEAM);
    H = zeros(length(BPU.OFDM_PILOT_F),PA.N_BEAM);
    rss_pwr = zeros(PA.N_BEAM,1);
    SNR = zeros(PA.N_BEAM,1);
    noise_pwr = zeros(PA.N_BEAM,1);
    maxk_pos = -99*ones(3,PA.N_BEAM);
    maxk_pks = -99*ones(3,PA.N_BEAM); 

    % 1. Gen tx data
    assert(BPU.PN_INTERVAL > length(BPU.ieee11ad_PREAMBLE));
    if BPU.DO_OFDM == 1
        payload = [BPU.OFDM_PREAMBLE; zeros(BPU.PN_INTERVAL-length(BPU.OFDM_PREAMBLE),1)];
        pre_pad = BPU.AMP*zeros(BPU.TX_POWER_AMP_WAIT+BPU.PA_INITIAL_DELAY,1); %BPU.AMP*exp(1j*2*pi*rand(BPU.TX_POWER_AMP_WAIT+BPU.PA_INITIAL_DELAY,1)); ... %BPU.AMP*ones(BPU.TX_POWER_AMP_WAIT+BPU.PA_INITIAL_DELAY,1);... repmat(header,(BPU.TX_POWER_AMP_WAIT+BPU.PA_INITIAL_DELAY)/255,1);
        post_pad = BPU.AMP*zeros(BPU.N_TRAIL_BEAM*BPU.PN_INTERVAL,1); %BPU.AMP*exp(1j*2*pi*rand(BPU.N_TRAIL_BEAM*BPU.PN_INTERVAL,1));
        tx_data = [pre_pad; repmat([payload],PA.N_BEAM,1); post_pad]; % trailing zeros help prevent USRP from getting lower values near the end of transmission
    else
        payload = [BPU.ieee11ad_PREAMBLE; zeros(BPU.PN_INTERVAL-length(BPU.ieee11ad_PREAMBLE),1)];
        pre_pad = BPU.AMP*zeros(BPU.TX_POWER_AMP_WAIT+BPU.PA_INITIAL_DELAY,1); %BPU.AMP*exp(1j*2*pi*rand(BPU.TX_POWER_AMP_WAIT+BPU.PA_INITIAL_DELAY,1)); ... %BPU.AMP*ones(BPU.TX_POWER_AMP_WAIT+BPU.PA_INITIAL_DELAY,1);... repmat(header,(BPU.TX_POWER_AMP_WAIT+BPU.PA_INITIAL_DELAY)/255,1);
        post_pad = BPU.AMP*zeros(BPU.N_TRAIL_BEAM*BPU.PN_INTERVAL,1); %BPU.AMP*exp(1j*2*pi*rand(BPU.N_TRAIL_BEAM*BPU.PN_INTERVAL,1));
        tx_data = [pre_pad; repmat([payload],PA.N_BEAM,1); post_pad]; % trailing zeros help prevent USRP from getting lower values near the end of transmission
    end
    assert(iscolumn(tx_data), "gen_tx sanity1");
    write_complex_binary([tx_data], BPU.TX_DATA_PATH);

    % 2. PA control
    if PA.EN_CMOD_A7
        % This works on Linux if there are no other serial devices connected
        % To find the serial ports available to Matlab, use the seriallist command
        uartfh = serial(PA.CMOD_A7_DEV,'BaudRate', 115200);
        fopen(uartfh);
        pa_ctl(PA.TX_CB_ENTRIES, PA.TX_IF_GAIN, PA.TX_BRG_PORT, 1, PA.GAP_CYC, uartfh);
        pa_ctl(PA.RX_CB_ENTRIES, PA.RX_IF_GAIN, PA.RX_BRG_PORT, 0, PA.GAP_CYC, uartfh);
        fclose(uartfh);
    end
    
    % 3. USRP tx/rx
    retry = BPU.MAX_RETRY_CNT;
    while retry >0
        try
            % USRP x310 NI-RIO (192.168.137.5)
            BPU.RUN_USRP_CMD = sprintf('%s \\\n--tx-args="%s" --tx-subdev="A:0" --tx-ant="TX/RX" --tx-rate=%s --tx-freq=%s --tx-gain=%s \\\n--rx-args="%s" --rx-subdev="A:0" --rx-ant="RX2" --rx-rate=%s --rx-freq=%s --rx-gain=%s \\\n--tx-settling=%s --rx-settling=%s \\\n--tx-file="%s" \\\n--rx-file="%s" \\\n--nsamps=%s',...
                BPU.USRP_EXECFILE, ...
                "type=x300,resource=RIO0", string(BPU.FS), string(BPU.FREQ), string(BPU.TX_RF_GAIN),...
                "type=x300,resource=RIO0", string(BPU.FS), string(BPU.FREQ), string(BPU.RX_RF_GAIN),...
                sprintf("%.6f",BPU.TX_SETTLING_TIME), sprintf("%.6f",BPU.RX_SETTLING_TIME),...
                BPU.TX_DATA_PATH, BPU.RX_DATA_PATH, string(BPU.NUM_RX_SAMP));
 
            run_cmd(BPU.RUN_USRP_CMD, {"UHD_IMAGES_DIR", "/usr/share/uhd/images", "UHD_RFNOC_DIR", "/usr/local/share/uhd/rfnoc"})
            fid = fopen("./uhd/RUN_USRP_CMD.log", "w");
            fprintf(fid,"%s",BPU.RUN_USRP_CMD);
            fclose(fid);
            break;
        catch 
            retry = retry - 1;
%             run_cmd("sleep 0.5");
            if retry==0
                error(sprintf("All %d attempts to TX/RX with USRP failed.\n",BPU.MAX_RETRY_CNT));
            end
        end
    end

    % 4. process rx data
    if BPU.DO_OFDM == 1
        % for 5G NR experiment
        rx = read_complex_binary(BPU.RX_DATA_PATH);
        MinPeakHeight = db2mag(-10); %db2mag(-10); % <=10 db weaker than the strongest
        MinPeakProminence = 0.05;
        assert(BPU.PN_INTERVAL > length(BPU.OFDM_PREAMBLE) + length(BPU.OFDM_PILOT_F)+100);
        figure(1); plot(abs(rx)); hold on; plot((round(BPU.LOOPBACK_DELAY)+length(BPU.ieee11ad_CE))*ones(1,2), [0 1], '--')
    %     figure(11); plot(abs(gugv_xcorr(rx)));
    
        for ii=1:PA.N_BEAM
            rx_segments(:,ii) = rx(round(BPU.LOOPBACK_DELAY)+(ii-1)*BPU.PN_INTERVAL+[1:BPU.PN_INTERVAL]);
            search_range = round(BPU.LOOPBACK_DELAY)+(ii-1)*BPU.PN_INTERVAL + [1:length(BPU.OFDM_PREAMBLE)];
            [r, lag] = gugv_xcorr(rx(search_range));
            [M,I] = max(abs(r)); % figure; plot(abs(r));
            if ii==1
                fprintf("First peak pos: %d\n", lag(I));
            end
            actual_delay = search_range(1)+(lag(I)-1)+length(BPU.ieee11ad_CE) + ...
                BPU.OFDM_CP_LEN - BPU.FFT_OFFSET;
            rss_pwr(ii) = sum(abs(rx(actual_delay+[1:length(BPU.OFDM_PILOT_F)]).^2));
            noise_pwr(ii) = sum(abs(rx(actual_delay+length(BPU.OFDM_PILOT_F)+[1:length(BPU.OFDM_PILOT_F)])).^2);
            SNR(ii) = db(rss_pwr(ii)/noise_pwr(ii),'power');
%             figure(1); plot(abs(rx)); hold on; plot((actual_delay+2*length(BPU.OFDM_PILOT_F))*ones(1,2), [0 1], '--')

    %         fprintf("beam SNR: %.2f dB\n",SNR(ii)); 
            
            rx_lts1_f = fft(rx(actual_delay+[1:length(BPU.OFDM_PILOT_F)]));
%             rx_lts2_f = fft(rx(actual_delay+length(BPU.OFDM_PILOT_F)+[1:length(BPU.OFDM_PILOT_F)]));
%             H(:,ii) = BPU.OFDM_PILOT_F.*(rx_lts1_f + rx_lts2_f)/2;
            H(:,ii) = rx_lts1_f.*conj(BPU.OFDM_PILOT_F);

            ch_t = ifft(H(:,ii));
            hh = [ch_t(end-BPU.FFTSIZE/2+1:end); ch_t(1:BPU.FFTSIZE/2)];
%             ch_t_shifted = fftshift(ch_t);
%             idx = fftshift([1:length(BPU.OFDM_PILOT_F)]);
            M = max(abs(hh));
            MinPeakHeight = db2mag(-10); % <=10 db weaker than the strongest
            MinPeakProminence = 0.05;
            MinPeakDistance = 0;
            [~,loc,~,prominence] = findpeaks(abs(hh)./M,"MinPeakProminence", MinPeakProminence, "MinPeakHeight", MinPeakHeight, "MinPeakDistance", MinPeakDistance);
%             if ii<=16
%                 figure(4); subplot(4,4,ii);
%                 findpeaks(abs(hh),"MinPeakProminence", M*MinPeakProminence, "MinPeakHeight", M*MinPeakHeight, "MinPeakDistance", MinPeakDistance);
%                 title(sprintf("%.1f",SNR(ii)));
%             end
            [M2,I2] = maxk(prominence, 3);
%             if (M<50)
%                 fprintf("Beam %d: Max peak less than 50\n", ii);
% %                 continue;
%             end
    %         fprintf("Maxk peak pos: %s\n",int2str(loc(I2).'));
            maxk_pos(1:length(I2),ii) = loc(I2);
            maxk_pks(1:length(I2),ii) = hh(loc(I2));   
        end
        



%         rx = read_complex_binary(BPU.RX_DATA_PATH);
%         lts_t = BPU.LTS_T;
%         lts_f = BPU.LTS_F;
%         LTS_CORR_THRESH = 0.8;
%         SC_IND_PILOTS = [8 22 44 58];                           % Pilot subcarrier indices
%         SC_IND_DATA = [2:7 9:21 23:27 39:43 45:57 59:64];     % Data subcarrier indices
%         N_SC = 64;                                     % Number of subcarriers
%         CP_LEN = 16;
%         FFT_OFFSET = 8;
%         DO_APPLY_CFO_CORRECTION = 0;
%         figure(1); plot(abs(rx));
%         assert(2*length(BPU.OFDM_PREAMBLE)+100 <= BPU.PN_INTERVAL);
%         for ii=1:PA.N_BEAM
%             rx_segments(:,ii) = rx(round(BPU.LOOPBACK_DELAY)+(ii-1)*BPU.PN_INTERVAL+[1:BPU.PN_INTERVAL]);
%             search_range = round(BPU.LOOPBACK_DELAY)+(ii-1)*BPU.PN_INTERVAL + [1:length(BPU.OFDM_PREAMBLE)*2];
%             raw_rx_dec = rx(search_range);
%             lts_corr = abs(conv(conj(fliplr(lts_t.')), sign(raw_rx_dec.')));
% %             figure; plot(lts_corr, '.-');
%             lts_peaks = find(lts_corr > LTS_CORR_THRESH*max(lts_corr));
%              % Select best candidate correlation peak as LTS-payload boundary
%             [LTS1, LTS2] = meshgrid(lts_peaks,lts_peaks);
%             [lts_second_peak_index,y] = find(LTS2-LTS1 == length(lts_t));
%             % Stop if no valid correlation peak was found
%             if(isempty(lts_second_peak_index))
%                 fprintf('No LTS Correlation Peaks Found!\n');
%                 continue;
%             end
%             payload_ind = lts_peaks(max(lts_second_peak_index)) + 1;
%             lts_ind = payload_ind-160;
%             if(DO_APPLY_CFO_CORRECTION)
%                 %Extract LTS (not yet CFO corrected)
%                 rx_lts = raw_rx_dec(lts_ind : lts_ind+159);
%                 rx_lts1 = rx_lts(-64+-FFT_OFFSET + [97:160]);
%                 rx_lts2 = rx_lts(-FFT_OFFSET + [97:160]);
%             
%                 %Calculate coarse CFO est
%                 rx_cfo_est_lts = mean(unwrap(angle(rx_lts2 .* conj(rx_lts1))));
%                 rx_cfo_est_lts = rx_cfo_est_lts/(2*pi*64);
%             else
%                 rx_cfo_est_lts = 0;
%             end
%             % Apply CFO correction to raw Rx waveform
%             rx_cfo_corr_t = exp(-1i*2*pi*rx_cfo_est_lts*[0:length(raw_rx_dec)-1].');
%             rx_dec_cfo_corr = raw_rx_dec .* rx_cfo_corr_t;
%             
%             % Re-extract LTS for channel estimate
%             rx_lts = rx_dec_cfo_corr(lts_ind : lts_ind+159);
%             rx_lts1 = rx_lts(-64+-FFT_OFFSET + [97:160]);
%             rx_lts2 = rx_lts(-FFT_OFFSET + [97:160]);
%             
%             rx_lts1_f = fft(rx_lts1);
%             rx_lts2_f = fft(rx_lts2);
%             
%             % Calculate channel estimate from average of 2 training symbols
%             rx_H_est = lts_f .* (rx_lts1_f + rx_lts2_f)/2;
%             H(:,ii) = rx_H_est;
% 
%             actual_delay = search_range(1) + (lts_ind - 1) -1;
%             rss_pwr(ii) = sum(abs(rx(actual_delay+[1:length(BPU.OFDM_PREAMBLE)]).^2));
%             noise_pwr(ii) = sum(abs(rx(actual_delay+length(BPU.OFDM_PREAMBLE)+100+[1:length(BPU.OFDM_PREAMBLE)])).^2);
%             SNR(ii) = db(rss_pwr(ii)/noise_pwr(ii),'power');
% 
%             ch_t_shifted = fftshift(ifft(rx_H_est));
%             ch_t = ifft(rx_H_est);
%             idx = fftshift([1:length(BPU.LTS_F)]);
%             M = max(abs(ch_t));
%             MinPeakHeight = db2mag(-10); % <=10 db weaker than the strongest
%             MinPeakProminence = 0.05;
%             MinPeakDistance = 0;
%             [~,loc,~,prominence] = findpeaks(abs(ch_t_shifted)./M,"MinPeakProminence", MinPeakProminence, "MinPeakHeight", MinPeakHeight, "MinPeakDistance", MinPeakDistance);
%             if ii<=16
%                 figure(4); subplot(4,4,ii);
%                 findpeaks(abs(ch_t_shifted),"MinPeakProminence", M*MinPeakProminence, "MinPeakHeight", M*MinPeakHeight, "MinPeakDistance", MinPeakDistance);
%                 title(sprintf("%.1f",SNR(ii)));
%             end
%             [M2,I2] = maxk(prominence, 3);
%     %         fprintf("Maxk peak pos: %s\n",int2str(loc(I2).'));
%             maxk_pos(1:length(I2),ii) = idx(loc(I2));
%             maxk_pks(1:length(I2),ii) = ch_t(idx(loc(I2)));
% %             idx(loc(I2))
%         end


    else
        rx = read_complex_binary(BPU.RX_DATA_PATH);
        MinPeakHeight = db2mag(-10); %db2mag(-10); % <=10 db weaker than the strongest
        MinPeakProminence = 0.05;
        rows = PA.N_BEAM; %min(16, PA.N_BEAM);
        assert(BPU.PN_INTERVAL > 2*length(BPU.ieee11ad_CE)+100);
        figure(1); plot(abs(rx)); hold on; plot((round(BPU.LOOPBACK_DELAY)-length(BPU.ieee11ad_STF))*ones(1,2), [0 1], '--')
    %     figure(11); plot(abs(gugv_xcorr(rx)));
    
        for ii=1:rows
            rx_segments(:,ii) = rx(round(BPU.LOOPBACK_DELAY)+(ii-1)*BPU.PN_INTERVAL+[1:BPU.PN_INTERVAL]);
            search_range = round(BPU.LOOPBACK_DELAY)+(ii-1)*BPU.PN_INTERVAL + [1:length(BPU.ieee11ad_PREAMBLE)+20];
            [r, lag] = gugv_xcorr(rx(search_range));
            [M,I] = max(abs(r));
            plot_range1 = I-length(BPU.ieee11ad_STF):I+length(BPU.ieee11ad_CE);
            plot_range2 = I-20:I+50;
            peak_diff_threshold_db = -5;
            range3 = 1:length(plot_range2);
            if ii==1
                fprintf("First peak pos: %d\n", lag(I));
            end
%             figure(2); 
%             subplot(rows,3,(ii-1)*3+1); plot(abs(rx));
%             subplot(rows,3,(ii-1)*3+2); plot(lag(plot_range1), abs(r(plot_range1)));
%             subplot(rows,3,(ii-1)*3+3); plot(range3, abs(r(plot_range2))); hold on;
%             plot([1 length(plot_range2)],M*10^(peak_diff_threshold_db/10)*ones(1,2),'--'); hold on;
%             selected_idx = abs(r(plot_range2))>M*10^(peak_diff_threshold_db/10);
%             text(range3(selected_idx),abs(r(plot_range2(selected_idx))), 'x');
%             title("First Peak Detection");
%             fprintf("Max peak pos: %d\n", lag(I));
    
            actual_delay = search_range(1)+lag(I)-1;
            rss_pwr(ii) = sum(abs(rx(actual_delay+[1:length(BPU.ieee11ad_CE)]).^2));
            noise_pwr(ii) = sum(abs(rx(actual_delay+length(BPU.ieee11ad_CE)+100+[1:length(BPU.ieee11ad_CE)])).^2);
            SNR(ii) = db(rss_pwr(ii)/noise_pwr(ii),'power');
    %         fprintf("beam SNR: %.2f dB\n",SNR(ii)); 
    
    %         figure(3); plot(range3, abs(r(plot_range2))); hold on;
            if (M<50)
                fprintf("Beam %d: Max peak less than 50\n", ii);
                continue;
            end
            [~,loc,~,prominence] = findpeaks(abs(r(plot_range2))./M,"MinPeakProminence", MinPeakProminence, "MinPeakHeight", MinPeakHeight);
            complex_pks = r(plot_range2);
            [M2,I2] = maxk(prominence, 3);
            loc2 = loc(I2); %sort(loc(I2));
            pks2 = complex_pks(loc2);
    %         fprintf("Maxk peak pos: %s\n",int2str(loc(I2).'));
            absolute_idx_in_rx = lag(plot_range2);
            maxk_pos(1:length(I2),ii) = absolute_idx_in_rx(loc2);
            maxk_pks(1:length(I2),ii) = pks2;
            
%             if ii<=16
%                 figure(4);  
%                 subplot(4,4,ii); 
%                 plot(lag(plot_range2), abs(r(plot_range2))); hold on;
%                 for jj=1:length(loc2)
%                     plot(maxk_pos(jj,ii), abs(maxk_pks(jj,ii)), 'o');
%                 end
% %                 findpeaks(abs(r(plot_range2)),"MinPeakProminence", M*MinPeakProminence, "MinPeakHeight", M*MinPeakHeight);
%                 title(sprintf("%.1f",SNR(ii)));
%             end
            
%             actual_delay2 = search_range(1)+absolute_idx_in_rx(loc2)-1;
    %         for jj = 1:length(actual_delay2)
    %             p = sum(abs(rx(actual_delay2(jj)+[1:length(BPU.ieee11ad_CE)]).^2));
    %             snrrr(ii,jj) = db(p/noise_pwr(ii),'power');
    %         end
        end
    end
end