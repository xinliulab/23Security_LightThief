function [xcorr_val, lag] = GuGvXcorr(rx, Params)
    [gucor, lag] = xcorr(rx, dmgRotate(Params.Gu));
    gvcor = xcorr(rx, dmgRotate(Params.Gv));
    xcorr_val = gucor(1:end-512) + gvcor(1+512:end);
    lag = lag(1:end-512);
end