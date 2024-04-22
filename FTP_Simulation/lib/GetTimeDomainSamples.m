function [y_noise, H] = GetTimeDomainSamples(Params)
    y = zeros(ceil(Params.Multipath(end,2)*Params.Fs) + 2*length(Params.Preamble), Params.M); 
    H = zeros(Params.N, Params.N);
    for ii=1:size(Params.Multipath, 1)
        Gain = Params.Multipath(ii,1);
        ToF = Params.Multipath(ii,2);
        AoD = Params.Multipath(ii,3);
        AoA = Params.Multipath(ii,4);
    
        g_t = steervec(Params.PhasedArray.getElementPosition()/Params.Lambda, [AoD;0]);
        g_r = steervec(Params.PhasedArray.getElementPosition()/Params.Lambda, [AoA;0]);
        H_k = Gain.*g_r.*g_t';
        H = H + H_k;
    
        y(round(ToF*Params.Fs) + [1:length(Params.Preamble)], :) = y(round(ToF*Params.Fs) + ...
                    [1:length(Params.Preamble)], :) + (Params.u'*H_k*Params.v).*Params.Preamble;
    end
    % Apply CFO
    if abs(Params.CFO)>0
        RandomStartPhase = exp(1j*2*pi*rand(1, Params.M));
        y_cfo = y.*RandomStartPhase.*exp(1j*2*pi*Params.CFO/Params.Fs*[0:size(y,1)-1].'); 
    else
        y_cfo = y;
    end
    % Add noise
    for ii=1:Params.M
        y_noise(:,ii) = awgn(y_cfo(:,ii), Params.SNR, 'measured');
    end
end