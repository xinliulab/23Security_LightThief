function [BPU, PA] = sanity_check(BPU, PA)
    BPU.PA_INITIAL_DELAY       = round(BPU.PA_INITAIL_DELAY_TIME*BPU.FS);
    BPU.PN_INTERVAL            = round(BPU.PN_INTERVAL_TIME*BPU.FS);
    BPU.TX_POWER_AMP_WAIT      = round(BPU.TX_POWER_AMP_WAIT_TIME*BPU.FS);
    BPU.RX_POWER_AMP_WAIT      = round(BPU.RX_POWER_AMP_WAIT_TIME*BPU.FS); 
    BPU.TX_SETTLING_TIME = round(BPU.TX_SETTLING_TIME,9);
    BPU.RX_SETTLING_TIME = round(BPU.RX_SETTLING_TIME,9);
    BPU.NUM_TX_SAMP = BPU.TX_POWER_AMP_WAIT + BPU.PA_INITIAL_DELAY + ...
        (PA.N_BEAM+BPU.N_TRAIL_BEAM)*BPU.PN_INTERVAL+1000; 
    if BPU.RX_SETTLING_TIME < BPU.TX_SETTLING_TIME
        BPU.NUM_RX_SAMP = BPU.FS*(BPU.TX_SETTLING_TIME-BPU.RX_SETTLING_TIME) +...
            BPU.NUM_TX_SAMP;
        BPU.LOOPBACK_DELAY = BPU.FS*(BPU.TX_SETTLING_TIME-BPU.RX_SETTLING_TIME) +...
            BPU.TX_POWER_AMP_WAIT + BPU.PA_INITIAL_DELAY + ...
            BPU.USRP_HARDWARE_DELAY(BPU.FS) + (PA.EN_CMOD_A7>0) + ...
            140*(BPU.TX_POWER_AMP_WAIT_TIME>6e-3);
    else
        BPU.NUM_RX_SAMP = BPU.RX_POWER_AMP_WAIT + ...
            (BPU.NUM_TX_SAMP - BPU.TX_POWER_AMP_WAIT);
        % X310 NI-RIO
        if BPU.DO_OFDM == 1
            BPU.LOOPBACK_DELAY = BPU.RX_POWER_AMP_WAIT + BPU.PA_INITIAL_DELAY + ...
            BPU.USRP_HARDWARE_DELAY(BPU.FS) + (PA.EN_CMOD_A7>0)*0 - (BPU.FS==200e6)*4080;
        else
            BPU.LOOPBACK_DELAY = BPU.RX_POWER_AMP_WAIT + BPU.PA_INITIAL_DELAY + ...
            BPU.USRP_HARDWARE_DELAY(BPU.FS) + (PA.EN_CMOD_A7>0)*0 + ...
            length(BPU.ieee11ad_STF) - (BPU.FS==200e6)*4080;
        end
        
        % 4080 is nedded when prepadding zeros for 750 us

%         BPU.LOOPBACK_DELAY = BPU.RX_POWER_AMP_WAIT + BPU.PA_INITIAL_DELAY + ...
%             BPU.USRP_HARDWARE_DELAY(BPU.FS) + (PA.EN_CMOD_A7>0) - ...
%             18360*(BPU.TX_POWER_AMP_WAIT_TIME>6e-3) + length(BPU.ieee11ad_STF);
    end

    % sanity check
    if BPU.DO_OFDM
        assert(BPU.PA_INITIAL_DELAY+length(BPU.PN_SEQ)+length(BPU.OFDM_PREAMBLE) < BPU.PN_INTERVAL, "sanity1 OFDM"); % PN is guaranteed to fall within a valid state of the PA
    else
%         assert(BPU.PA_INITIAL_DELAY+length(BPU.PN_SEQ) < BPU.PN_INTERVAL, "sanity1"); % PN is guaranteed to fall within a valid state of the PA
    end
    assert(BPU.PA_INITAIL_DELAY_TIME + length(BPU.ieee11ad_PREAMBLE)/BPU.FS < BPU.PN_INTERVAL_TIME, "sanity1");
    assert(length(PA.TX_CB_ENTRIES) == PA.N_BEAM + PA.N_BEAM_WASTE, "sanity2");
    assert(length(PA.RX_CB_ENTRIES) == PA.N_BEAM + PA.N_BEAM_WASTE, "sanity3");
%     assert(mod(PA.N_BEAM,4)==0, "sanity4");
    assert(BPU.AMP>=0 &&  BPU.AMP<=1, "sanity5");
%     assert((PA.N_BEAM*BPU.PN_INTERVAL_TIME+BPU.PA_INITAIL_DELAY_TIME+BPU.RX_POWER_AMP_WAIT_TIME)*BPU.FS < 24e4, "sanity6");
%     assert(mod(BPU.RX_POWER_AMP_WAIT_TIME,BPU.PN_INTERVAL_TIME)==0, "sanity6");
    assert(mod(PA.N_BEAM_WASTE,1)==0, "sanity6");
    assert(mod(PA.GAP_CYC,1)==0, "sanity7");
    assert(BPU.RX_SETTLING_TIME < BPU.TX_SETTLING_TIME || round(BPU.RX_SETTLING_TIME + BPU.RX_POWER_AMP_WAIT_TIME,9) == round(BPU.TX_SETTLING_TIME + BPU.TX_POWER_AMP_WAIT_TIME,9), "sanity8")
%     assert(BPU.TX_SETTLING_TIME-BPU.RX_SETTLING_TIME>=40e-3, "sanity8")
    assert(PA.EN_CMOD_A7==0 || (length(PA.TX_CB_ENTRIES)<=170 && length(PA.RX_CB_ENTRIES)<=170), "sanity9");
    
    fprintf(sprintf("NUM_TX_SAMP: %d, TIME: %.2f ms\nNUM_RX_SAMP: %d, TIME: %.2f ms\nNUM_BEAM: %d\n", BPU.NUM_TX_SAMP, BPU.NUM_TX_SAMP/BPU.FS*1e3, BPU.NUM_RX_SAMP, BPU.NUM_RX_SAMP/BPU.FS*1e3, PA.N_BEAM));
end