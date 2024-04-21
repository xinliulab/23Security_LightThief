function [xcorr_val, lag] = gugv_xcorr(rx)
    [Ga128,Gb128] = wlanGolaySequence(128);
    Gu = [-Gb128; -Ga128; Gb128; -Ga128];
    Gv = [-Gb128; Ga128; -Gb128; -Ga128];
    [gucor, lag] = xcorr(rx, dmgRotate(Gu));
    gvcor = xcorr(rx, dmgRotate(Gv));
    xcorr_val = gucor(1:end-512) + gvcor(1+512:end);
    lag = lag(1:end-512);
end