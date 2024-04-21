%% initialization
% path(path, '/home/chen7323/Downloads/cvx-a64');
% USRP X310
% for ((i=0;i<$(nproc --all);i++)); do sudo cpufreq-set -c $i -r -g performance; done
path(path, './lib');
path(path, './mat_files');

load("Ga128.mat"); 
load("Gb128.mat");
Gu = [-Gb128; -Ga128; Gb128; -Ga128];
Gv = [-Gb128; Ga128; -Gb128; -Ga128];
pn_1024 = [-1,1,1,-1,-1,1,1,-1,1,-1,1,1,-1,1,1,1,1,1,1,1,1,-1,-1,-1,1,1,-1,-1,-1,-1,1,1,-1,-1,1,1,1,1,1,1,-1,1,1,-1,-1,-1,1,1,-1,1,-1,-1,-1,-1,1,-1,1,1,1,-1,1,1,-1,1,1,-1,-1,-1,-1,1,-1,-1,1,-1,1,1,-1,1,1,1,-1,1,-1,-1,1,-1,-1,-1,-1,1,1,-1,-1,1,-1,-1,-1,1,-1,-1,1,-1,1,-1,1,-1,-1,1,-1,1,-1,1,-1,1,1,1,1,-1,-1,1,1,-1,1,1,-1,1,1,1,-1,-1,-1,1,-1,-1,1,-1,1,1,-1,1,1,1,-1,1,1,1,-1,-1,1,1,1,-1,-1,-1,1,-1,-1,1,-1,1,-1,-1,1,1,1,1,-1,-1,1,1,-1,-1,1,-1,1,1,-1,-1,1,-1,1,-1,1,1,1,-1,-1,-1,1,-1,-1,1,1,-1,1,-1,-1,-1,1,1,-1,1,-1,1,1,-1,-1,1,1,1,1,1,-1,1,-1,-1,1,-1,1,-1,-1,-1,1,-1,1,-1,1,1,1,1,1,1,-1,1,-1,1,-1,1,1,1,1,-1,1,1,-1,-1,-1,-1,1,1,-1,-1,1,1,1,-1,1,-1,-1,-1,1,-1,-1,-1,1,1,-1,1,1,1,-1,-1,-1,1,1,1,-1,-1,1,1,-1,-1,-1,1,-1,1,1,1,-1,1,1,-1,1,-1,1,-1,1,1,1,1,-1,1,1,1,1,1,1,-1,1,1,1,-1,1,1,-1,1,-1,-1,1,1,-1,-1,-1,-1,-1,-1,1,-1,1,1,1,1,-1,-1,-1,1,-1,-1,1,1,1,1,-1,-1,-1,-1,-1,1,-1,-1,1,-1,-1,1,-1,1,1,-1,-1,1,-1,-1,-1,1,-1,1,-1,1,1,1,-1,1,1,1,1,1,-1,1,1,1,-1,-1,-1,1,1,-1,-1,1,1,1,-1,-1,1,1,-1,-1,-1,1,1,-1,1,1,1,-1,-1,-1,-1,1,1,-1,1,-1,-1,-1,1,1,1,1,1,-1,-1,-1,-1,1,-1,-1,1,-1,1,1,-1,-1,1,-1,-1,-1,1,1,-1,1,-1,-1,-1,-1,1,1,-1,1,-1,1,1,-1,-1,-1,-1,1,1,1,1,1,1,1,-1,-1,-1,-1,-1,1,-1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,1,1,-1,1,1,-1,1,1,-1,-1,1,1,1,-1,-1,-1,1,1,-1,-1,-1,1,1,-1,1,1,1,1,-1,1,-1,-1,-1,1,-1,-1,1,1,-1,-1,1,-1,1,1,-1,1,1,1,1,1,1,1,-1,1,-1,-1,1,-1,-1,-1,-1,1,-1,1,1,-1,-1,-1,1,-1,1,-1,-1,-1,1,-1,1,-1,1,1,1,1,-1,-1,1,-1,-1,-1,-1,1,-1,1,-1,-1,-1,1,1,-1,-1,1,-1,1,-1,1,1,-1,1,1,1,1,-1,1,-1,1,1,-1,-1,-1,-1,1,-1,1,1,-1,-1,-1,1,1,1,1,1,1,-1,1,-1,1,-1,1,1,-1,-1,-1,-1,1,1,1,1,-1,1,1,1,-1,-1,-1,1,1,1,1,-1,1,-1,1,1,1,-1,1,-1,1,1,1,-1,1,-1,-1,-1,-1,1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,1,-1,1,1,1,1,1,1,1,-1,1,-1,1,-1,-1,-1,1,1,1,1,-1,1,-1,-1,-1,-1,-1,1,-1,1,-1,1,-1,-1,-1,1,1,-1,-1,1,1,-1,1,-1,-1,-1,-1,-1,1,1,-1,1,-1,1,1,1,-1,1,1,-1,-1,1,1,1,1,1,1,1,-1,1,-1,-1,-1,1,1,1,1,-1,1,-1,-1,1,-1,1,-1,-1,-1,-1,-1,1,1,1,-1,-1,-1,1,1,-1,1,-1,-1,-1,1,-1,-1,1,-1,1,1,-1,1,-1,-1,1,1,1,1,-1,-1,1,-1,1,-1,1,1,-1,-1,1,1,1,1,-1,1,-1,1,1,1,1,1,1,1,-1,-1,1,1,1,1,-1,1,1,1,-1,-1,1,1,-1,-1,-1,-1,-1,-1,1,1,1,1,-1,-1,1,-1,1,1,-1,-1,-1,-1,1,-1,-1,1,1,-1,-1,-1,1,1,1,1,-1,1,-1,1,1,1,-1,-1,-1,1,1,-1,1,-1,-1,-1,-1,-1,-1,-1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,-1,-1,1,1,-1,1,-1,-1,1,1,1,1,-1,-1,1,-1,1,1,-1,1,-1,1,-1,-1,1,1,1,-1,1,-1,-1,-1,1,-1,1,1,-1,-1,-1,1,-1,1,-1,1,-1,1,-1,-1,1,-1,1,1,1,1,1,-1,1,-1,1,-1,1,-1,1,-1,1,-1,-1,-1,-1,1,1,1,1,1,-1,-1,1,-1,1,-1,1,1,1,-1,-1,-1,1,-1,1,1,-1,-1,-1,1,1,1,1,1,1,-1,1,-1,-1,-1,-1,-1,-1,-1,1,1,1,1,-1,-1,1,1,-1,-1,-1,-1,-1,-1,-1,-1,1,1,-1,1,-1,-1,1,1,-1,-1,-1,1,-1,1].';
pn_255 = [ 1.,  1,  1,  1,  1,  1,  1,  1, -1,  1,  1, -1,  1, -1, -1,  1,  1,  1, -1, -1, -1, -1,  1, -1,  1, -1, 1, -1, -1, -1, -1, -1, -1,  1, -1,  1,  1, -1, -1, 1,  1,  1, -1,  1,  1, -1, -1,  1, -1, -1, -1, -1, -1,  1, -1, -1, -1, -1,  1, -1, -1,  1,  1,  1,  1, 1, -1,  1, -1,  1,  1,  1,  1, -1,  1, -1, -1, -1, 1, -1,  1, -1, -1,  1, -1,  1,  1,  1, -1, -1, -1, 1, -1, -1, -1,  1, -1, -1,  1, -1, -1,  1, -1,  1, -1, -1, -1,  1,  1, -1, -1,  1, -1,  1,  1, -1,  1, -1,  1, -1,  1, -1,  1,  1, -1,  1,  1, -1, -1, -1, 1, -1,  1,  1,  1,  1,  1, -1, -1,  1,  1, -1, -1, -1, -1, -1, -1, -1,  1,  1, -1,  1,  1,  1, -1,  1, -1, -1,  1, -1, -1, -1,  1,  1,  1,  1,  1,  1, -1, -1, -1, -1, -1,  1,  1,  1, -1,  1, -1,  1, -1, -1, 1,  1, -1,  1, -1,  1,  1, -1, -1, -1, -1,  1,  1, -1, -1, -1,  1,  1, -1,  1, -1, -1, -1, -1,  1,  1, 1,  1, -1, -1, -1,  1,  1,  1, -1, -1,  1,  1,  1, 1, -1,  1,  1,  1, -1, -1,  1, -1, -1,  1,  1, -1, -1,  1,  1, -1,  1,  1, -1,  1,  1,  1,  1, -1, -1, 1, -1,  1, -1,  1,  1,  1, -1].';
pn_interval_time = containers.Map({200e6,100e6,40e6,20e6,10e6},[50e-6,200e-6, (10e-3*40e6-18360)/40/40e6,(10e-3*20e6-18360)/4/20e6,(10e-3*10e6-18360)/26/10e6]);

BPU.AMP                    = 0.7;
BPU.FS                     = 200e6;
BPU.FREQ                   = 2400e6; %200e6;
BPU.TX_RF_GAIN             = 20;
BPU.RX_RF_GAIN             = 10;
BPU.PA_INITAIL_DELAY_TIME  = 4e-6;%4e-6;
BPU.PN_INTERVAL_TIME       = pn_interval_time(BPU.FS); %10e-6; % 8164us/26=314us, pn_1024 takes 102.4us@10MHz
BPU.RX_POWER_AMP_WAIT_TIME = 750e-6 + 20.4e-6; % X310 has 4080 sample shift when prepend 750 us zeros
BPU.TX_POWER_AMP_WAIT_TIME = 750e-6 + 20.4e-6; %0*10e-3; % >=1ms,tested for USRP B210
BPU.TX_SETTLING_TIME       = 0.5;
BPU.RX_SETTLING_TIME       = BPU.TX_SETTLING_TIME + BPU.TX_POWER_AMP_WAIT_TIME - BPU.RX_POWER_AMP_WAIT_TIME;
BPU.N_TRAIL_BEAM           = 0*50;
BPU.MAX_RETRY_CNT          = 5;
BPU.USRP_HARDWARE_DELAY    = containers.Map({200e6,100e6,40e6,20e6,10e6},[121,82,166,166,47]); % 200e6 needs to be measured! 100e6 for X310 NI-RIO, USRP B210 hardware introduces 166 sample delay @20Mhz, 47@10Mhz
% BPU.RX_NOISE_POWER         = containers.Map({5,10,15,20},[1.6245e-4,2.3901e-4,3.5004e-4,3.4517e-4]); %[2.2e-4,4.2e-4,9.5e-4,0.0019] % USRP B210 hardware introduces 166 sample delay @20Mhz, 47@10Mhz
BPU.RX_NOISE_POWER         = containers.Map({5,10,15,20},[2.2e-4,4.2e-4,9.5e-4,0.0019]); % USRP B210 hardware introduces 166 sample delay @20Mhz, 47@10Mhz
BPU.REF_SAMPLE_PWR_DB      = containers.Map({5,10,15,20}, [0.3947,5.3781,10.2910,14.7773]);
BPU.REF_PWR_DBM            = -20; % Agilent E8257D -20 dBm
BPU.PN_SEQ                 = pn_1024;
BPU.LTS_F                  = [0 1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1].';
BPU.LTS_T                  = ifft(BPU.LTS_F, 64);
BPU.ieee11ad_STF           = dmgRotate([repmat(Ga128,16,1); -Ga128]);
BPU.ieee11ad_CE            = dmgRotate([Gu;Gv;-Gb128]);
BPU.ieee11ad_PREAMBLE      = [BPU.ieee11ad_STF; BPU.ieee11ad_CE];
BPU.FFTSIZE                = 64; %1666; %512; %4096; % for 120kHz sc spacing, 200e6/120e3 -> 1666
BPU.SC_IND                 = [1:64]; %[9:658 mod([-658:-9],BPU.FFTSIZE)]; %[4:200 mod([-200:-4],512)]; %[67:3:1600 mod(-1600:3:-67,4096)];
BPU.OFDM_PILOT_F           = zeros(BPU.FFTSIZE,1); 
carrier = nrCarrierConfig('NSizeGrid',275,'SubcarrierSpacing',120);
pdsch = nrPDSCHConfig('PRBSet',0:274);
sym = nrPDSCHDMRS(carrier,pdsch);
% ind = nrPDSCHDMRSIndices(carrier,pdsch);
% txGrid = nrResourceGrid(carrier);
% txGrid(ind) = sym;
% figure; imagesc(abs(txGrid))
BPU.OFDM_PILOT_F(BPU.SC_IND) = sym(1:length(BPU.SC_IND)); % figure; plot((-100e6: 200e6/BPU.FFTSIZE: 100e6-1)/1e6, fftshift(abs(BPU.OFDM_PILOT_F)))
BPU.OFDM_PILOT_F             = BPU.LTS_F;
BPU.OFDM_PILOT_T             = ifft(BPU.OFDM_PILOT_F); 
BPU.OFDM_CP_LEN              = 16; %512;
BPU.FFT_OFFSET               = 8;
t = BPU.OFDM_PILOT_T./max(abs(BPU.OFDM_PILOT_T));
cp = t(length(BPU.OFDM_PILOT_T)-BPU.OFDM_CP_LEN+1:length(BPU.OFDM_PILOT_T));
BPU.OFDM_PREAMBLE = [BPU.ieee11ad_CE; cp; t;];
BPU.DO_OFDM                = 0;
% BPU.RUN_USRP_CMD           = "bash /home/chen7323/Downloads/mmw-calibration-sim/uhd/run.sh";
BPU.TX_DATA_PATH           = "./mat_files/tx_data.mat";
BPU.RX_DATA_PATH           = "./mat_files/usrp_samples.mat";
BPU.USRP_ARGS              = "serial=31245AF"; %"serial=31245B5";
BPU.USRP_EXECFILE          = "/home/chen7323/Downloads/uhd/host/build/examples/txrx_loopback_to_file";
% BPU.PA_INITIAL_DELAY       = 0;
% BPU.PN_INTERVAL            = 0;
% BPU.TX_POWER_AMP_WAIT      = 0;
% BPU.RX_POWER_AMP_WAIT      = 0;
% BPU.NUM_TX_SAMP            = 0;
% BPU.NUM_RX_SAMP            = 0;
% BPU.LOOPBACK_DELAY         = 0;


PA.N_BEAM        = 1; %8+124; %16*40; % max ~170
PA.EN_CMOD_A7    = 1;
PA.TX_RF_MODULE  = 5; % Qualcomm index, 0-7
PA.RX_RF_MODULE  = 7; % Qualcomm index, 0-7
PA.TX_IP         = 1; % 192.168.137.x
PA.RX_IP         = 2;
PA.FREQ          = 60480e6;
PA.LAM           = physconst('LightSpeed')/PA.FREQ;
PA.ANT_MAP       = containers.Map({'row1','row2','row3','row4','col1','24','32'},{[8 1 2 11 13 15],[6 7 5 9 16 14],[22 23 21 26 32 30],[24 17 18 27 29 31],[3 1 7 23 17 19],setdiff([1:32],[3 4 12 10 19 20 28 25]), [1:32]});
PA.ACTIVE_ANT    = PA.ANT_MAP('32');%setdiff([1:32],[3 4 12 10 19 20 28 25])
PA.REFANT        = 1;
PA.PHASE_CAL     = zeros(32,1); % in rad
PA.MAG_CAL       = ones(4,32);
PA.CMOD_A7_DEV   = '/dev/ttyUSB1';
PA.TX_CB_NAME    = "./codebooks/test.mat";
PA.RX_CB_NAME    = "./codebooks/test.mat";
PA.N_BEAM_WASTE  = (BPU.RX_POWER_AMP_WAIT_TIME-20.4e-6)/BPU.PN_INTERVAL_TIME; % X310 NI-RIO 200e6 Msps
% PA.N_BEAM_WASTE  = (BPU.RX_POWER_AMP_WAIT_TIME*BPU.FS-(BPU.RX_POWER_AMP_WAIT_TIME>6e-6)*18360)/(BPU.PN_INTERVAL_TIME*BPU.FS);
PA.TX_CB_ENTRIES = zeros(1,PA.N_BEAM_WASTE+PA.N_BEAM);%reshape(repmat([0:3],PA.N_BEAM/4,1),1,PA.N_BEAM);%[0:PA.N_BEAM-1]; % repmat([0],1,32);
PA.RX_CB_ENTRIES = zeros(1,length(PA.TX_CB_ENTRIES));
PA.TX_BRG_PORT   = 5; % Tx phased array connection on control FPGA
PA.RX_BRG_PORT   = 8; % Rx phased array connection on control FPGA
PA.TX_IF_GAIN    = 1; % Attenuation index of IF AMPlifier on phased array
PA.RX_IF_GAIN    = 1; % Attenuation index of IF AMPlifier on phased array
PA.CMOD_A7_CLK   = 12e6;
PA.GAP_CYC       = round(PA.CMOD_A7_CLK*BPU.PN_INTERVAL_TIME); 

[BPU, PA] = sanity_check(BPU, PA);

run_cmd(sprintf("python ./M-Cube-Hostcmds/load_codebook.py %d 1 %d %s",PA.TX_IP,2^PA.TX_RF_MODULE,PA.TX_CB_NAME));
run_cmd(sprintf("python ./M-Cube-Hostcmds/load_codebook.py %d 0 %d %s",PA.RX_IP,2^PA.RX_RF_MODULE,PA.RX_CB_NAME));
load("cal32_new_taoffice.mat"); % somhow this still works for node 1 mod 5
PA.PHASE_CAL(PA.ACTIVE_ANT) = calibration_vec;
load("magcal.mat");
PA.MAG_CAL = mag_cal_vec;


idx_offset = 0;
aco_cbsize = [124]; %[8:4:124];
savedata = 0;
BPU.DO_OFDM =0;
az = [-80:1:80];
pa_tx  = [2]; % 1-15, 1 indicates max gain
pa_rx  = [2]; assert(length(pa_tx)==length(pa_rx));
bpu_tx = [20]; assert(length(bpu_tx)==length(pa_tx));
bpu_rx = [5];  assert(length(bpu_rx)==length(pa_rx));

tic
for ii=1:length(pa_tx)
    PA.TX_IF_GAIN = pa_tx(ii); 
    PA.RX_IF_GAIN = pa_rx(ii);
    BPU.TX_RF_GAIN = bpu_tx(ii);
    BPU.RX_RF_GAIN = bpu_rx(ii);

    % micro-benchmark
    save_folder = "./exp_data/ftp/mirco-benchmark";
    [data] = ftp_micro_benchmark(idx_offset+ii,az,aco_cbsize,savedata,save_folder,BPU,PA);
    % SNR
    save_folder = "./exp_data/ftp/exp";
    [data] = ftp_exp(idx_offset+ii,az,aco_cbsize,savedata,save_folder,BPU,PA); 
end
toc