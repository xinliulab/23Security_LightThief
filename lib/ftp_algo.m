function [v_multipath,v2_multipath,v_dominantpath,path_ang,path_gain,unique_pos] = ftp_algo(cb, BPU, PA, maxk_pos, maxk_pks, SNR, rx, r98, showplot)
    % correlation peaks = uHv = rx_directional_gain * wl_channel * tx_directional_gain
    % H = sum(a_k*arx(theta,phi)*atx(theta,phi)^T)
    % obtain uH and find the optimal v
    load(cb);
    cb_size = length(beam_weight);
    est_wlch_rx_dir_gain = -99*ones(3,cb_size);
    occurence_threshold = round(cb_size/10); % a path should be present in at least some number of beams
    assert(cb_size >= occurence_threshold);
    az=[-80:80]; 
    el=[0];

    if BPU.DO_OFDM ~= 1
        % 1. sanitize peak pos, find up to 3 peaks with most occurrences
        unique_pos = unique(maxk_pos(maxk_pos~=-99));
        occurence =zeros(1,length(unique_pos));
        for ii=1:length(unique_pos)
            occurence(ii) = sum(maxk_pos==unique_pos(ii),'all');
            fprintf("pos %d (occurence=%d, threshold=%d)\n", unique_pos(ii),occurence(ii),occurence_threshold);
        end
        %     [M,I] = maxk(occurence, 5);
        [M,I] = maxk(occurence, 2);
        unique_pos2 = [];
        for ii=1:length(I)
            %         if M(ii)>=occurence_threshold && all(abs(unique_pos2-unique_pos(I(ii)))>1)
            if M(ii)>=occurence_threshold
                unique_pos2 = [unique_pos2; unique_pos(I(ii))];
            end
        end
        unique_pos = unique_pos2;
        %     unique_pos = [14,17,34];
        fprintf("detected peak pos: %s\n", num2str(unique_pos.'));


        %     maxk_pos = -99*ones(3,cb_size);
        %     maxk_pks = -99*ones(3,cb_size);
        %     for ii=1:cb_size
        % %         search_range = round(BPU.LOOPBACK_DELAY)+(ii-1)*BPU.PN_INTERVAL + [1:length(BPU.ieee11ad_PREAMBLE)+20];
        %         rxx = rx(:,ii);
        %         [r, lag] = gugv_xcorr(rxx);
        %         [M,I] = max(abs(r));
        %         plot_range2 = I-20:I+20;
        % %         [~,loc,~,prominence] = findpeaks(abs(r(plot_range2))./M,"MinPeakProminence", MinPeakProminence, "MinPeakHeight", MinPeakHeight);
        %         complex_pks = r(plot_range2);
        % %         [M2,I2] = maxk(prominence, 3);
        % %         loc2 = loc(I2); %sort(loc(I2));
        %         loc2 = unique_pos;
        %         pks2 = complex_pks(loc2);
        % %         fprintf("Maxk peak pos: %s\n",int2str(loc(I2).'));
        %         maxk_pos(1:length(loc2),ii) = loc2;
        %         maxk_pks(1:length(pks2),ii) = pks2;
        %     end

        % 2. find path angle for each peak
        path_ang = 0*ones(2, length(unique_pos));
        for ii=1:length(unique_pos)
            power_vec = zeros(cb_size, 1);
            occurence_idx = find(sum(maxk_pos==unique_pos(ii))==1);
            %         power_vec(occurence_idx) = abs(maxk_pks(maxk_pos==unique_pos(ii)));

            max_peak_power_each_beam = max(abs(maxk_pks),[],1).';
            %         adjusted_SNR_each_peak = SNR(occurence_idx) + 10*log10(abs(maxk_pks(maxk_pos==unique_pos(ii)))./max_peak_power_each_beam(occurence_idx));
            %         power_vec(occurence_idx) = 10.^(adjusted_SNR_each_peak/10);
            adjusted_pwr_each_peak = r98(occurence_idx).*abs(maxk_pks(maxk_pos==unique_pos(ii)))./max_peak_power_each_beam(occurence_idx);
            power_vec(occurence_idx) = adjusted_pwr_each_peak;
            [csang2] = get_cs_result(cb,power_vec,az,el,PA);
            path_ang(1, ii) = csang2(1);
        end
        fprintf("detected path ang: %s\n", num2str(path_ang(1,:)));
        %     plot_codebook(cb, az,[-20:20],PA.FREQ);


        % 3. find complex gain for each peak
        pa = get_phased_array(PA.FREQ);
        %     figure;viewArray(pa, "ShowIndex", "All", 'ShowNormals',true)
        %     ang_test = [-6;0];
        %     sv = steervec(pa.getElementPosition()/PA.LAM,ang_test);
        %     elementPos_y_in_halfwav = 2.5 - [4 3 4 3 3 5 4 5 2 1 2 2 1 0 0 1 4 3 4 3 3 5 4 5 1 2 2 2 1 0 0 1].';
        %     wy = 2*pi*0.5*cos(deg2rad(ang_test(2)))*sin(deg2rad(ang_test(1)))*elementPos_y_in_halfwav;
        %     wz = 2*pi*0.5*sin(deg2rad(ang_test(2)))*ones(length(elementPos_y_in_halfwav),1);
        %     angle([sv exp(1j*(wy+wz))])
        mean_bc1 = zeros(length(unique_pos),1);
        mean_bc2 = zeros(length(unique_pos),1);
        debug_bc = zeros(cb_size, 2);
        phase_std = zeros(length(unique_pos),1);
        phase_within_threshold = zeros(length(unique_pos),1);
        for ii=1:length(unique_pos)
            beam_idx = find(sum(maxk_pos==unique_pos(ii))==1);
            bf_vec = zeros(length(PA.ACTIVE_ANT), length(beam_idx));
            for jj=1:length(beam_idx)
                etype = str2num(beam_weight{beam_idx(jj)}{1});
                psh = str2num(beam_weight{beam_idx(jj)}{2});
                mag = zeros(32,1);
                for kk=1:32
                    mag(kk) = PA.MAG_CAL((psh(kk)+1), kk);
                end
                bf_vec(:,jj) = mag.*exp(-1j*2*pi/4*psh)./exp(1j*PA.PHASE_CAL);
            end

            est_atx = conj(steervec(pa.getElementPosition()/PA.LAM, path_ang(:,ii)));
            tx_dir_gain = (est_atx.'*bf_vec).'; % (PA.N_BEAM, 1)
            target_pks = maxk_pks(maxk_pos==unique_pos(ii));
            assert(iscolumn(tx_dir_gain) && iscolumn(target_pks));
            est_wlch_rx_dir_gain(maxk_pos==unique_pos(ii)) = target_pks./tx_dir_gain;

            %         figure(32);
            %         subplot(2,length(unique_pos),ii); plot(angle(target_pks)); title(sprintf("pos:%d, phase",unique_pos(ii)));
            %         subplot(2,length(unique_pos),length(unique_pos)+ii); plot(abs(target_pks)); title(sprintf("pos:%d, abs",unique_pos(ii)));

            bc = est_wlch_rx_dir_gain(maxk_pos==unique_pos(ii));
            mean_bc1(ii) = mean(bc);
            mean_bc2(ii) = mean(bc./abs(bc).*sqrt(abs(target_pks)));
            %         debug_bc(:,ii) = bc;
            phase_std(ii) = std(abs(angle(bc./mean(bc)))); %std(mod(angle(bc),2*pi));
            bc_phase = mod(angle(bc),2*pi);
            phase_within_threshold(ii) = sum(abs(angle(bc./mean(bc))) < 0.5)/length(beam_idx);
            %         fprintf("percentage of measurements with phase falling within 0.5 rad from the mean %.1f\n", phase_within_threshold(ii));

            if showplot
                figure(33);
                subplot(3,length(unique_pos),ii);
                plot(bc_phase); hold on;
                plot([1 length(bc)],mod(angle(mean_bc1(ii)),2*pi)*[1 1]);
                plot([1 length(bc)],mod(angle(mean_bc2(ii)),2*pi)*[1 1]);
                %         [abs(bc) SNR(beam_idx)]
                title(sprintf("pos:%d, phase of bc\n std=%.1f rad\n%.2f",unique_pos(ii),phase_std(ii)),phase_within_threshold(ii));

                subplot(3,length(unique_pos),length(unique_pos)+ii);
                plot(abs(bc));
                title(sprintf("pos:%d, abs of bc",unique_pos(ii)));

                subplot(3,length(unique_pos),2*length(unique_pos)+ii);
                plot(SNR(beam_idx));
                title(sprintf("pos:%d, SNR of bc",unique_pos(ii)));

                %             figure(34);
                %             subplot(2,2,ii); plot(bc_phase); hold on;
                %             plot([1 length(bc)],mod(angle(mean_bc1(ii)),2*pi)*[1 1]);
                %             xlabel("Beam index"); ylabel("Phase (rad)"); ylim([0 2*pi]);
                %             title(sprintf("path %d, std=%.1f rad",ii,phase_std(ii)));
                %             subplot(2,2,2+ii); plot(abs(bc));  hold on;
                %             plot([1 length(bc)],abs(mean(bc))*[1 1]);
                %             xlabel("Beam index"); ylabel("Magnitude");
                %             title(sprintf("path %d, mean pwr=%.1f dB",ii,db(abs(mean(bc)))));
            end

            %         for jj=1:length(az)
            %             aatx = conj(steervec(pa.getElementPosition()/PA.LAM, [az(jj);0]));
            %             tx_dir_gain = (aatx.'*bf_vec).';
            %             t(jj) = std(angle(target_pks./tx_dir_gain));
            %         end
            %         figure; plot(t);
        end
        mean_pk_pwr1 = abs(mean_bc1);
        mean_pk_phase1 = angle(mean_bc1);
        fprintf("Average peak power diff: %s dB\n", num2str(db(mean_pk_pwr1./mean_pk_pwr1(1)).'));
        fprintf("Average peak phase diff: %s\n", num2str(mean_pk_phase1.'-mean_pk_phase1(1)));

        unique_pos_ = unique_pos(phase_std<=0.5 | phase_within_threshold>0.7);
        path_ang_ = path_ang(:,phase_std<=0.5 | phase_within_threshold>0.7);
        mean_bc1_ = mean_bc1(phase_std<=0.5 | phase_within_threshold>0.7);

        if isempty(unique_pos_)
            unique_pos = unique_pos(1);
            path_ang = path_ang(:,1);
            mean_bc1 = mean_bc1(1);
        end

        %     unique_pos = [13,14];
        %     path_ang = [-45 45;0 0];
        %     mean_bc1 = [1 1];

        %     mean_pk_pwr2 = abs(mean_bc2);
        %     mean_pk_phase2 = angle(mean_bc2);
        %     fprintf("Average peak power diff: %s dB\n", num2str(db(mean_pk_pwr2./mean_pk_pwr2(1), 'power').'));
        %     fprintf("Average peak phase diff: %s\n", num2str(mean_pk_phase2.'-mean_pk_phase2(1)));

        %     figure(55); plot(angle(debug_bc./debug_bc(:,1)));

        %     % 4. remove CFO within each probe
        %     common_path_pos = -99;
        %     for ii=1:length(unique_pos)
        %         if (sum(maxk_pos==unique_pos(ii),'all')==PA.N_BEAM)
        %             fprintf("peak pos %d is present for all beams.\n", unique_pos(ii));
        %             common_path_pos = unique_pos(ii);
        %             break;
        %         end
        %     end
        %     if common_path_pos == -99
        %         error("no common path found!\n");
        %     end
        %     est_wlch_rx_dir_gain_nocfo = est_wlch_rx_dir_gain./exp(1j*angle(est_wlch_rx_dir_gain(maxk_pos==common_path_pos)).')

        % 5. reconstruct Hrx = uH
        path_gain = zeros(length(unique_pos),1);
        est_Hrx = zeros(1,length(PA.ACTIVE_ANT));
        v2_multipath = zeros(length(PA.ACTIVE_ANT),1);
        for ii=1:length(unique_pos)
            est_atx = conj(steervec(pa.getElementPosition()/PA.LAM, path_ang(:,ii)));
            path_gain(ii) = mean_bc1(ii);
            est_Hrx = est_Hrx + path_gain(ii)*est_atx.';

            % v2
            path_gain(ii) = mean_bc1(ii);
            v2_multipath = v2_multipath + (1/path_gain(ii))*steervec(pa.getElementPosition()/PA.LAM, path_ang(:,ii));
        end
        v_multipath = exp(1j*angle(est_Hrx'));
        %     figure; plot(angle([v_multipath v2_multipath]));
        %     v_multipath = v2_multipath;
        v_dominantpath = steervec(pa.getElementPosition()/PA.LAM, path_ang(:,1));
    else
        % OFDM
%         % method 1
%         sanitized_maxk_pos = -99*ones(size(maxk_pos));
%         sanitized_maxk_pks = -99*ones(size(maxk_pks));
%         npaths = 0;
%         for ii=1:size(maxk_pos,1)
%             a = maxk_pos(ii,maxk_pos(ii,:)~=-99);
%             if ~isempty(a)
%                 npaths = npaths + 1;
%             end
%             stda = std(a);
%             meana = mean(a);
%             idx = maxk_pos(ii,:)~=-99 & abs(maxk_pos(ii,:)-meana)<stda;
%             sanitized_maxk_pos(ii,idx) = maxk_pos(ii,idx);
%             sanitized_maxk_pks(ii,idx) = maxk_pks(ii,idx);
%             fprintf("peak %d is present in %d beams\n", ii, sum(idx));
% 
%             figure(77); color = 'brg';
%             plot(a, [color(ii) '.']); hold on;
%             plot([1 size(maxk_pos,2)], mean(a)*ones(1,2), [color(ii) '-']);
%             plot([1 size(maxk_pos,2)], (mean(a)+std(a))*ones(1,2), [color(ii) '--']);
%             plot([1 size(maxk_pos,2)], (mean(a)-std(a))*ones(1,2), [color(ii) '--']);
%         
%             figure(78);
%             plot(maxk_pks(ii,idx), [color(ii) '.']); hold on;
%         end


        % method 2
        % get the strongest peak from each probe
        b = maxk_pos(1,:);
        good_idx = b~=-99; %& abs(b-mean(b))<std(b);
        figure; plot(b, 'b.'); hold on; 
        plot([1 size(b,2)], (mean(b)+std(b))*ones(1,2), ['r--']);
        plot([1 size(b,2)], (mean(b)-std(b))*ones(1,2), ['r--']);
        
        % try and see if there are clusters of peaks
        final_idx = ones(1,length(b));
        final_C = median(b(good_idx));
        for ii=2:3
            [idx,C,sumd,D] = kmeans(reshape(b(good_idx),[],1),ii,'Distance','cityblock');
            dist = diff(sort(C));
            if all(abs(dist)>5) % 2.5 ns threshold for peaks to be considered different
                final_idx(good_idx) = idx.';
                final_C = C;
            end
        end
%         idx1 = maxk_pos(1,:)~=-99 & maxk_pos(1,:)>=399 & maxk_pos(1,:)<=406; 
%         idx2 = maxk_pos(1,:)~=-99 & maxk_pos(1,:)>390 & maxk_pos(1,:)<=398;        
        
        npaths = length(final_C);
        sanitized_maxk_pos = -99*ones(size(maxk_pos));
        sanitized_maxk_pks = -99*ones(size(maxk_pks));
        figure(71); clf;
        for ii=1:length(final_C)
            idx = good_idx & final_idx==ii;
            sanitized_maxk_pos(ii,idx) = C(ii);
            sanitized_maxk_pks(ii,idx) = maxk_pks(1,idx);

            color = 'brg';
            plot(b(idx), [color(ii) '.']); hold on;
        end

%         sanitized_maxk_pos(1,idx1) = 222;
%         sanitized_maxk_pks(1,idx1) = maxk_pks(1,idx1);
%         sanitized_maxk_pos(2,idx2) = 333;
%         sanitized_maxk_pks(2,idx2) = maxk_pks(1,idx2);


        % 2. find path angle for each peak
        path_ang = 0*ones(2, npaths);
        for ii=1:npaths
            power_vec = zeros(cb_size, 1);
            occurence_idx = find(sanitized_maxk_pos(ii,:)~=-99);
            power_vec(occurence_idx) = abs(sanitized_maxk_pks(ii, sanitized_maxk_pos(ii,:)~=-99)).^2;

%             max_peak_power_each_beam = max(abs(maxk_pks),[],1).';
    %         adjusted_SNR_each_peak = SNR(occurence_idx) + 10*log10(abs(maxk_pks(maxk_pos==unique_pos(ii)))./max_peak_power_each_beam(occurence_idx));
    %         power_vec(occurence_idx) = 10.^(adjusted_SNR_each_peak/10);
%             adjusted_pwr_each_peak = r98(occurence_idx).*abs(maxk_pks(maxk_pos==unique_pos(ii)))./max_peak_power_each_beam(occurence_idx);
%             power_vec(occurence_idx) = adjusted_pwr_each_peak;
            [csang2] = get_cs_result(cb,power_vec,az,el,PA);
            path_ang(1, ii) = csang2(1);
        end
        fprintf("detected path ang: %s\n", num2str(path_ang(1,:)));
        %     plot_codebook(cb, az,[-20:20],PA.FREQ);

        % 3. find complex gain for each peak
        pa = get_phased_array(PA.FREQ);
        %     figure;viewArray(pa, "ShowIndex", "All", 'ShowNormals',true)    
        mean_bc1 = zeros(npaths,1);
        mean_bc2 = zeros(npaths,1);
        debug_bc = zeros(cb_size, 2);
        phase_std = zeros(npaths,1);
        phase_within_threshold = zeros(npaths,1);

        for ii=1:npaths
            beam_idx = find(sanitized_maxk_pos(ii,:)~=-99);
            bf_vec = zeros(length(PA.ACTIVE_ANT), length(beam_idx));
            for jj=1:length(beam_idx)
                etype = str2num(beam_weight{beam_idx(jj)}{1});
                psh = str2num(beam_weight{beam_idx(jj)}{2});
                mag = zeros(32,1);
                for kk=1:32
                    mag(kk) = PA.MAG_CAL((psh(kk)+1), kk);
                end
                bf_vec(:,jj) = mag.*exp(-1j*2*pi/4*psh)./exp(1j*PA.PHASE_CAL);
            end

            est_atx = conj(steervec(pa.getElementPosition()/PA.LAM, path_ang(:,ii)));
            tx_dir_gain = (est_atx.'*bf_vec).'; % (PA.N_BEAM, 1)
            target_pks = sanitized_maxk_pks(ii, sanitized_maxk_pos(ii,:)~=-99).';
            assert(iscolumn(tx_dir_gain) && iscolumn(target_pks));
            bc = target_pks./tx_dir_gain;
            mean_bc1(ii) = mean(bc);
%             mean_bc2(ii) = mean(bc./abs(bc).*sqrt(abs(target_pks )));
            %         debug_bc(:,ii) = bc;
            phase_std(ii) = std(abs(angle(bc./mean(bc)))); %std(mod(angle(bc),2*pi));
            bc_phase = mod(angle(bc),2*pi);
            phase_within_threshold(ii) = sum(abs(angle(bc./mean(bc))) < 0.5)/length(beam_idx);
            %         fprintf("percentage of measurements with phase falling within 0.5 rad from the mean %.1f\n", phase_within_threshold(ii));

            if showplot
                figure(33);
                subplot(3,npaths,ii);
                plot(bc_phase); hold on;
                plot([1 length(bc)],mod(angle(mean_bc1(ii)),2*pi)*[1 1]);
%                 plot([1 length(bc)],mod(angle(mean_bc2(ii)),2*pi)*[1 1]);
                %         [abs(bc) SNR(beam_idx)]
                title(sprintf("path %d, phase of bc\n std=%.1f rad\n%.2f",ii,phase_std(ii)),phase_within_threshold(ii));

                subplot(3,npaths,npaths+ii);
                plot(abs(bc));
                title(sprintf("path %d, abs of bc",ii));

                subplot(3,npaths,2*npaths+ii);
                plot(SNR(beam_idx));
                title(sprintf("path %d, SNR of bc",ii));

%                 figure(34);
%                 subplot(2,2,ii); plot(bc_phase); hold on;
%                 plot([1 length(bc)],mod(angle(mean_bc1(ii)),2*pi)*[1 1]);
%                 xlabel("Beam index"); ylabel("Phase (rad)"); ylim([0 2*pi]);
%                 title(sprintf("path %d, std=%.1f rad",ii,phase_std(ii)));
%                 subplot(2,2,2+ii); plot(abs(bc));  hold on;
%                 plot([1 length(bc)],abs(mean(bc))*[1 1]);
%                 xlabel("Beam index"); ylabel("Magnitude");
%                 title(sprintf("path %d, mean pwr=%.1f dB",ii,db(abs(mean(bc)))));
            end
        end
        mean_pk_pwr1 = abs(mean_bc1);
        mean_pk_phase1 = angle(mean_bc1);
        fprintf("Average peak power diff: %s dB\n", num2str(db(mean_pk_pwr1./mean_pk_pwr1(1)).'));
        fprintf("Average peak phase diff: %s\n", num2str(mean_pk_phase1.'-mean_pk_phase1(1)));

        paths = [1:npaths];
        paths_ = paths(phase_std<=0.5 | phase_within_threshold>0.7);
        path_ang_ = path_ang(:,phase_std<=0.5 | phase_within_threshold>0.7);
        mean_bc1_ = mean_bc1(phase_std<=0.5 | phase_within_threshold>0.7);

        if isempty(paths_)
            paths = 1;
            path_ang = path_ang(:,1);
            mean_bc1 = mean_bc1(1);
        else
            paths = paths_;
            path_ang = path_ang_;
            mean_bc1 = mean_bc1_;
        end
        unique_pos = paths;

        % 5. reconstruct Hrx = uH
        path_gain = zeros(length(paths),1);
        est_Hrx = zeros(1,length(PA.ACTIVE_ANT));
        v2_multipath = zeros(length(PA.ACTIVE_ANT),1);
        for ii=1:length(paths)
            est_atx = conj(steervec(pa.getElementPosition()/PA.LAM, path_ang(:,ii)));
            path_gain(ii) = mean_bc1(ii);
            est_Hrx = est_Hrx + path_gain(ii)*est_atx.';

            % v2
            path_gain(ii) = mean_bc1(ii);
            v2_multipath = v2_multipath + (1/path_gain(ii))*steervec(pa.getElementPosition()/PA.LAM, path_ang(:,ii));
        end
        v_multipath = exp(1j*angle(est_Hrx'));
        %     figure; plot(angle([v_multipath v2_multipath]));
        %     v_multipath = v2_multipath;
        v_dominantpath = steervec(pa.getElementPosition()/PA.LAM, path_ang(:,1));
    end
end