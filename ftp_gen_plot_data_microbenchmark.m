input_folder = "D:/Lab computer/mmw-calibration-sim/exp_data/swift2.0/micro-benchmark";
output_folder = "./ftp_plot_scripts";
PA.FREQ          = 60480e6;
PA.LAM           = physconst('LightSpeed')/PA.FREQ;
PA.ANT_MAP       = containers.Map({'row1','row2','row3','row4','col1','24','32'},{[8 1 2 11 13 15],[6 7 5 9 16 14],[22 23 21 26 32 30],[24 17 18 27 29 31],[3 1 7 23 17 19],setdiff([1:32],[3 4 12 10 19 20 28 25]), [1:32]});
PA.ACTIVE_ANT    = PA.ANT_MAP('32');%setdiff([1:32],[3 4 12 10 19 20 28 25])
PA.PHASE_CAL     = zeros(32,1); % in rad
PA.MAG_CAL       = ones(4,32);
load("cal32_new_taoffice.mat"); % somhow this still works for node 1 mod 5
PA.PHASE_CAL(PA.ACTIVE_ANT) = calibration_vec;
load("magcal.mat");
PA.MAG_CAL = mag_cal_vec;

fontsize = 18;
linewidth = 2;
markersz = 16;
fig_size = [1 1 6 3];
close all;
for mm=1:3
    load(sprintf("%s/data%d.mat",input_folder,mm));
    BPU = data.bpu;
    PA =  data.pa;
    PA.N_BEAM = 124;
    create_cs_codebook(124, PA);
    cb = "./codebooks/cs.mat";
    [H30, r30, SNR30, n30, BPU, PA, maxk_pos30, maxk_pks30]=debug_peaks(data.rx_cs_probes, BPU, PA);
    if BPU.DO_OFDM == 1
        [maxk_pos11, maxk_pks11] = super_resolution(H30,0);
    else
        maxk_pos11 = maxk_pos30;
        maxk_pks11 = maxk_pks30;
    end
    [v_multipath,v2_multipath,v_dominantpath,path_ang,path_gain,unique_pos] = ftp_algo(cb, BPU, PA, maxk_pos11, maxk_pks11, SNR30, data.rx_cs_probes, r30,1);
    
    % PA.N_BEAM = length(data.az);
    % [H29, r29, SNR29, n29, BPU, PA, maxk_pos29, maxk_pks29]=debug_peaks(data.rx_ex_probes, BPU, PA);
    % figure; plot(data.az, r29);
    
    v2 = v_multipath./v_multipath(1).*exp(1j*PA.PHASE_CAL);
    v3 = v_dominantpath./v_dominantpath(1).*exp(1j*PA.PHASE_CAL);
    v4 = v2_multipath./v2_multipath(1).*exp(1j*PA.PHASE_CAL);
    
    PA.N_BEAM = 124;
    [H31, r31, SNR31, n31, BPU, PA, maxk_pos31, maxk_pks31]=debug_peaks(data.rx_aco_probes, BPU, PA);
    [rel_phase,rel_phase_avg,rel_phase_std] = get_rel_phase(r31);
    aco_activated_ant = [1:1+124/4];
    aco_sv = exp(1j*[0;-rel_phase_avg(aco_activated_ant(2:end)-1)]);
    % aco_sv = sum(steervec(pa.getElementPosition()/PA.LAM, [-30 45;0 0]),2).*exp(1j*PA.PHASE_CAL);
    
    % sv = [v2 aco_sv];
    % legs = ["SWIFT", "ACO"];
    % legs = [sprintf("SWIFT,%.1f",data.snr_cs_multipath(end)), ...
    %     sprintf("CS,%.1f",data.snr_cs_dominantpath(end)), ...
    %     sprintf("ACO,%.1f (ad,%.1f)",data.snr_aco(end),data.snr_11ad(end))];
    % sv2beam(sv,[-90:1:90],[-50:1:50],PA,legs)
    
    % 2d map, ang1 and ang2
    fname1 = sprintf("./figures/micro_ang%d.pdf",mm);
    fname2 = sprintf("./figures/micro_phase_mag%d.pdf",mm);
    
    PA.N_BEAM = 32;
    [H32, r32, SNR32, n32, BPU, PA, maxk_pos32, maxk_pks32]=debug_peaks(data.rx_aco_amp_probes, BPU, PA);
    Hrx = sqrt(r32).*exp(1j*[0;rel_phase_avg]);
    Hrx = Hrx(:).';
    
    vary_ang =[-20:20]; % degrees
    tmp8 = zeros(length(PA.ACTIVE_ANT),length(vary_ang),length(vary_ang));
    pa = get_phased_array(PA.FREQ);
    assert(length(unique_pos)==2);
    for ii=1:length(unique_pos)
        for jj=1:length(vary_ang)
            for kk = 1:length(vary_ang)
                if ii==1
                    a = conj(path_gain(ii)).*steervec(pa.getElementPosition()/PA.LAM, [path_ang(1,ii)+vary_ang(jj); 0]);
                    tmp8(:,jj,kk) = tmp8(:,jj,kk) + a;
                else
                    a = conj(path_gain(ii)).*steervec(pa.getElementPosition()/PA.LAM, [path_ang(1,ii)+vary_ang(kk); 0]);
                    tmp8(:,jj,kk) = tmp8(:,jj,kk) + a;
                end
            end
        end
    end
    
    snr_db1 = zeros(length(vary_ang),length(vary_ang));
    for jj=1:length(vary_ang)
        for kk = 1:length(vary_ang)
            t = normalize(tmp8(:,jj,kk).*exp(1j*PA.PHASE_CAL), 'norm');
            snr_db1(jj,kk) = db(Hrx*t);
        end
    end
    
    [M,I] = max(snr_db1(:));
    [I1,I2] = ind2sub(size(snr_db1),I);
    % fprintf("max az=%d, el=%d\n",vary_phase(I2), vary_amp(I1));
    
    data = [];
    data.z = snr_db1-max(snr_db1,[],'all');
    data.x = path_ang(1,2)+vary_ang;
    data.y = path_ang(1,1)+vary_ang;
    data.x2 = path_ang(1,2)+vary_ang(I2);
    data.y2 = path_ang(1,1)+vary_ang(I1);
    data.x3 = path_ang(1,2);
    data.y3 = path_ang(1,1);
    save(sprintf("%s/fig7_%d.mat",output_folder, mm), "data");

%     fig = figure('Units','inches', 'Position', fig_size); %6,4 for 2fig/column 
%     hold on;
%     clims = [-5 0];
%     imagesc(path_ang(1,2)+vary_ang, path_ang(1,1)+vary_ang,snr_db1-max(snr_db1,[],'all'), clims); 
%     plot(path_ang(1,2)+vary_ang(I2), path_ang(1,1)+vary_ang(I1), 'k^', 'MarkerSize', markersz, 'MarkerFaceColor', 'k');
%     plot(path_ang(1,2), path_ang(1,1), 'kd', 'MarkerSize', markersz, 'MarkerFaceColor', 'k');
%     c=colorbar;
%     ylabel(c, "SNR (dB)",'fontsize',fontsize);
%     colormap jet;
%     xlim(path_ang(1,2)+[vary_ang(1) vary_ang(end)]);
%     ylim(path_ang(1,1)+[vary_ang(1) vary_ang(end)]);
%     legend([sprintf("Oracle"),sprintf("Estimated")],'Location','northeast');
%     xlabel("\theta_2 (degree)", 'Interpreter','tex'); % Path 2 
%     ylabel("\theta_1 (degree)", 'Interpreter','tex'); % Path 1 
%     % xlim(phase1+[vary_phase(1) vary_phase(end)]);  ylim([min(snr_db1) 0]);
%     set(gca,'FontSize',fontsize);
%     % set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
% %     exportgraphics(fig,fname1,'Resolution',300);
    
    % 2d map, phase and amp
    vary_phase = [-180:1:180]; % degree
    vary_amp = db2mag([-10:10]); % db
    tmp8 = zeros(length(PA.ACTIVE_ANT),length(vary_amp),length(vary_phase));
    pa = get_phased_array(PA.FREQ);
    assert(length(unique_pos)==2);
    rel_complex_gain = path_gain(2)/path_gain(1);
    for ii=1:length(unique_pos)
        for jj=1:length(vary_amp)
            for kk = 1:length(vary_phase)
                if ii==1
                    a = 1*steervec(pa.getElementPosition()/PA.LAM, [path_ang(1,ii); -2] );
                    tmp8(:,jj,kk) = tmp8(:,jj,kk) + a;
                else
                    tmp8(:,jj,kk) = tmp8(:,jj,kk) + conj(vary_amp(jj)*exp(1j*deg2rad(vary_phase(kk)))*rel_complex_gain).*steervec(pa.getElementPosition()/PA.LAM, [path_ang(1,ii); -2]);
                end
            end
        end
    end
    
    snr_db1 = zeros(length(vary_amp),length(vary_phase));
    for jj=1:length(vary_amp)
        for kk = 1:length(vary_phase)
            t = normalize(tmp8(:,jj,kk).*exp(1j*PA.PHASE_CAL), 'norm');
            snr_db1(jj,kk) = db(Hrx*t);
        end
    end
    [M,I] = max(snr_db1(:));
    [I1,I2] = ind2sub(size(snr_db1),I);
    % fprintf("max az=%d, el=%d\n",vary_phase(I2), vary_amp(I1));
    
    data = [];
    data.z = snr_db1-max(snr_db1,[],'all');
    data.x = vary_phase;
    data.y = mag2db(vary_amp);
    data.x2 = vary_phase(I2);
    data.y2 = mag2db(vary_amp(I1));
    save(sprintf("%s/fig8_%d.mat",output_folder,mm), "data");

%     fig = figure('Units','inches', 'Position', fig_size); %6,4 for 2fig/column 
%     hold on;
%     clims = [-5 0];
%     imagesc(vary_phase,mag2db(vary_amp),snr_db1-max(snr_db1,[],'all'), clims); 
%     plot(vary_phase(I2), mag2db(vary_amp(I1)), 'k^', 'MarkerSize', markersz, 'MarkerFaceColor', 'k');
%     plot(0, 0, 'kd', 'MarkerSize', markersz, 'MarkerFaceColor', 'k');
%     c=colorbar;
%     ylabel(c, "SNR (dB)",'fontsize',fontsize);
%     colormap jet;
%     xlim([vary_phase(1) vary_phase(end)]);
%     ylim([mag2db(vary_amp(1)) mag2db(vary_amp(end))]);
%     legend([sprintf("Oracle"),sprintf("Estimated")],'Location','northeast');
%     xlabel("\delta (degree)", 'Interpreter','tex'); %Relative phase 
%     ylabel("\alpha (dB)", 'Interpreter','tex'); %Relative magnitude 
%     % xlim(phase1+[vary_phase(1) vary_phase(end)]);  ylim([min(snr_db1) 0]);
%     set(gca,'FontSize',fontsize);
%     % set(gca, 'XMinorTick','on', 'XMinorGrid','on', 'YMinorTick','on', 'YMinorGrid','on');
% %     exportgraphics(fig,fname2,'Resolution',300);
end