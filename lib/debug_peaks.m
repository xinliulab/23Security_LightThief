function [H, rss_pwr, SNR, noise_pwr, BPU, PA, maxk_pos, maxk_pks]=debug_peaks(rx, BPU,PA)
    H = [];
    rss_pwr = zeros(PA.N_BEAM,1);
    SNR = zeros(PA.N_BEAM,1);
    noise_pwr = zeros(PA.N_BEAM,1);
    maxk_pos = -99*ones(3,PA.N_BEAM);
    maxk_pks = -99*ones(3,PA.N_BEAM); 

    if BPU.DO_OFDM == 1
        H = zeros(length(BPU.OFDM_PILOT_F),PA.N_BEAM);
        MinPeakHeight = db2mag(-10); %db2mag(-10); % <=10 db weaker than the strongest
        MinPeakProminence = 0.05;
        assert(BPU.PN_INTERVAL > length(BPU.OFDM_PREAMBLE) + length(BPU.OFDM_PILOT_F)+100);
%         figure(1); plot(abs(rx)); hold on; plot((round(BPU.LOOPBACK_DELAY)+length(BPU.ieee11ad_CE))*ones(1,2), [0 1], '--')
    
        for ii=1:PA.N_BEAM
            search_range = (ii-1)*BPU.PN_INTERVAL + [1:BPU.PN_INTERVAL];
%             search_range = round(BPU.LOOPBACK_DELAY)+(ii-1)*BPU.PN_INTERVAL + [1:length(BPU.OFDM_PREAMBLE)];
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
            H(:,ii) = rx_lts1_f(:).*conj(BPU.OFDM_PILOT_F);

            ch_t = ifft(H(:,ii));
            hh = [ch_t(end-BPU.FFTSIZE/2+1:end); ch_t(1:BPU.FFTSIZE/2)];
%             ch_t_shifted = fftshift(ch_t);
%             idx = fftshift([1:length(BPU.OFDM_PILOT_F)]);
            M = max(abs(hh));
            MinPeakDistance = 0;
            [~,loc,~,prominence] = findpeaks(abs(hh)./M,"MinPeakProminence", MinPeakProminence, "MinPeakHeight", MinPeakHeight, "MinPeakDistance", MinPeakDistance);
            if ii<=8
                figure(4); subplot(2,4,ii);
                findpeaks(abs(hh),"MinPeakProminence", M*MinPeakProminence, "MinPeakHeight", M*MinPeakHeight, "MinPeakDistance", MinPeakDistance);
                title(sprintf("%.1f",SNR(ii)));
            end
            [M2,I2] = maxk(prominence, 3);
            if (M<50)
                fprintf("Beam %d: Max peak less than 50\n", ii);
%                 continue;
            end
    %         fprintf("Maxk peak pos: %s\n",int2str(loc(I2).'));
            maxk_pos(1:length(I2),ii) = loc(I2);
            maxk_pks(1:length(I2),ii) = hh(loc(I2));   
        end
    else
        H = zeros(64,PA.N_BEAM);
        for ii=1:PA.N_BEAM
            MinPeakHeight = db2mag(-10); % <=10 db weaker than the strongest
            MinPeakProminence = 0.05;
            search_range = (ii-1)*BPU.PN_INTERVAL + [1:BPU.PN_INTERVAL];
            [r, lag] = gugv_xcorr(rx(search_range));
            [M,I] = max(abs(r));
            plot_range1 = I-length(BPU.ieee11ad_STF):I+length(BPU.ieee11ad_CE);
            plot_range2 = I-20:I+50;
            peak_diff_threshold_db = -5;

            actual_delay = search_range(1)+lag(I)-1;
            rss_pwr(ii) = sum(abs(rx(actual_delay+[1:length(BPU.ieee11ad_CE)]).^2));
            noise_pwr(ii) = sum(abs(rx(actual_delay+length(BPU.ieee11ad_CE)+100+[1:length(BPU.ieee11ad_CE)])).^2);
            SNR(ii) = db(rss_pwr(ii)/noise_pwr(ii),'power');
            %         fprintf("beam SNR: %.2f dB\n",SNR(ii));

            [~,loc,~,prominence] = findpeaks(abs(r(plot_range2))./M,"MinPeakProminence", MinPeakProminence, "MinPeakHeight", MinPeakHeight);
            complex_pks = r(plot_range2);
            [M2,I2] = maxk(prominence, 3);
            loc2 = loc(I2); %sort(loc(I2));
            pks2 = complex_pks(loc2);
            %         fprintf("Maxk peak pos: %s\n",int2str(loc(I2).'));
            absolute_idx_in_rx = lag(plot_range2);
            maxk_pos(1:length(I2),ii) = absolute_idx_in_rx(loc2);
            maxk_pks(1:length(I2),ii) = pks2;
            zerolag_idx = find(lag(plot_range2)==0);
            if ~isempty(zerolag_idx)
                H(:,ii) = fft(r(plot_range2(zerolag_idx)+[0:63]));
            end
            
%             if ii<=8
%                 figure(4);
%                 subplot(2,4,ii);
%                 plot(lag(plot_range2), abs(r(plot_range2))); hold on;
%                 for jj=1:length(loc2)
%                     plot(maxk_pos(jj,ii), abs(maxk_pks(jj,ii)), 'o');
%                 end
%                 %                 findpeaks(abs(r(plot_range2)),"MinPeakProminence", M*MinPeakProminence, "MinPeakHeight", M*MinPeakHeight);
%                 title(sprintf("%.1f",SNR(ii)));
%             end
        end
    end    
end