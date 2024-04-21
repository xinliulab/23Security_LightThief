input_folder = "D:/Lab computer/mmw-calibration-sim/exp_data/swift2.0";
output_folder = "./";
for scenario = ["LOS", "NLOS"]
    % scenario = "NLOS";  %"NLOS"
    if scenario == "LOS"
        datasize = 49;
        load_folder = sprintf("%s/los_multipath",input_folder);
        good_idx = setdiff([1:datasize],[3,10,11,12,13,18,25,42]); % LOS dataset 51+
    elseif scenario == "NLOS"
        datasize = 30;
        load_folder = sprintf("%s/nlos_multipath",input_folder);
        good_idx = setdiff([1:datasize],[1]); % NLOS dataset 51+
    end
    offset = 50;
    load(sprintf("%s/data%d.mat",load_folder,offset+1));
    snr_cs_multipath    = zeros(datasize, length(data.aco_cbsize));
    snr_cs_multipath_v2 = zeros(datasize, length(data.aco_cbsize));
    snr_cs_dominantpath = zeros(datasize, length(data.aco_cbsize));
    snr_aco             = zeros(datasize, length(data.aco_cbsize));
    snr_11ad            = zeros(datasize, length(data.aco_cbsize));
    tpt_cs_multipath    = zeros(datasize, length(data.aco_cbsize));
    tpt_cs_multipath_v2 = zeros(datasize, length(data.aco_cbsize));
    tpt_cs_dominantpath = zeros(datasize, length(data.aco_cbsize));
    tpt_aco             = zeros(datasize, length(data.aco_cbsize));
    tpt_11ad            = zeros(datasize, length(data.aco_cbsize));
    for ii=1:datasize
        load(sprintf("%s/data%d.mat",load_folder, offset+ii));
        snr_cs_multipath(ii,:)    = data.snr_cs_multipath;
        snr_cs_multipath_v2(ii,:) = data.snr_cs_multipath_v2;
        snr_cs_dominantpath(ii,:) = data.snr_cs_dominantpath;
        snr_aco(ii,:)             = data.snr_aco;
        snr_11ad(ii,:)            = data.snr_11ad;

        tpt_cs_multipath(ii,:)    = data.tpt_cs_multipath;
        tpt_cs_multipath_v2(ii,:) = data.tpt_cs_multipath_v2;
        tpt_cs_dominantpath(ii,:) = data.tpt_cs_dominantpath;
        tpt_aco(ii,:)             = data.tpt_aco;
        tpt_11ad(ii,:)            = data.tpt_11ad;
        fprintf("#%d, bpu tx: %d, bpu rx: %d, pa tx: %d, pa rx: %d, snr: %d\n", ...
            ii,data.bpu.TX_RF_GAIN, data.bpu.RX_RF_GAIN, data.pa.TX_IF_GAIN, data.pa.RX_IF_GAIN, round(data.snr_cs_multipath(end)));
    end

    leg=["FTP", "ACO", "11ad"];
    linestyles = ["-", "--", "-.", ":",'-'];
    fig_size = [1 1 6 4];
    fontsize = 22;
    export_fname = '';
    p1 = [snr_cs_multipath(good_idx,3) snr_aco(good_idx,end) snr_11ad(good_idx,end)];
%     my_cdfplot(p1,"SNR (dB)",leg,linestyles,[],fontsize,fig_size,export_fname);

    [rate, mcs]= get_11ad_datarate(p1);
    rate = rate/(1760e6/160e6);
%     my_cdfplot(rate./1e6,"Throughput (Mbps)",leg,linestyles,[],fontsize,fig_size,export_fname);
    p2=rate;

    if scenario == "LOS"
        p = p1; save(sprintf("%s/fig9a.mat", output_folder), "p");
        p = p2; save(sprintf("%s/fig9b.mat", output_folder), "p");
    elseif scenario == "NLOS"
        p = p1; save(sprintf("%s/fig9c.mat", output_folder), "p");
        p = p2; save(sprintf("%s/fig9d.mat", output_folder), "p");
    end
end
