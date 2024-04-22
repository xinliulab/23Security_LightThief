function [v_star] = GetOptimalBeam(AoD, RelativeGains, Params)    
    g_t = steervec(Params.PhasedArray.getElementPosition()/Params.Lambda, [AoD.'; zeros(1, length(AoD))]);
    v_star = normalize(sum(RelativeGains'.*g_t, 2), 'norm');
end