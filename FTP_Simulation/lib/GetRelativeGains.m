function [RelativeGains] = GetRelativeGains(P_mk, PathToF, AoD, Params)    
    ToFs = unique(PathToF(PathToF~=-1));
    Z = sum(PathToF == ToFs, 1) == size(PathToF, 1);
    if any(Z)
        z = find(Z==1); % find all beam indices with all paths present
        g_t = steervec(Params.PhasedArray.getElementPosition()/Params.Lambda, [AoD.'; zeros(1, length(AoD))]);
        RelativeGains = P_mk(:, z)./(g_t'*Params.v(:, z));
        RelativeGains = mean(RelativeGains./RelativeGains(1,:), 2); % calibrate against the first peak
    else
        % Send One Extra Probe
        v = steervec(Params.PhasedArray.getElementPosition()/Params.Lambda, [AoD.'; zeros(1, length(AoD))]);
        Params.v = sum(v,2);
        Params.M = 1;
        [y, H] = GetTimeDomainSamples(Params);
        [P_mk, PathToF] = GetChannelImpulseResponse(y, Params);
        z =1;
        g_t = steervec(Params.PhasedArray.getElementPosition()/Params.Lambda, [AoD.'; zeros(1, length(AoD))]);
        RelativeGains = P_mk(:, z)./P_mk(1, z)./(g_t'*Params.v(:, z));
    end
end