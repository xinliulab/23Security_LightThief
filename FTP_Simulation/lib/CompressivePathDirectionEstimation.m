function [AoD] = CompressivePathDirectionEstimation(P_mk, PathToF, Params)
    Angles = [-80:80];
    SteerVectors = steervec(Params.PhasedArray.getElementPosition()/Params.Lambda, [Angles; zeros(1, length(Angles))]);
    NominalGains = Params.v'*SteerVectors;
    ToFs = unique(PathToF(PathToF~=-1));
    AoD = zeros(length(ToFs), 1);
    for ii=1:length(ToFs)
        p = zeros(Params.M, 1);
        BeamIdx = sum(PathToF==ToFs(ii),1)==1;
        p(BeamIdx) = P_mk(PathToF==ToFs(ii));
        % Using the magnitude part only and thus is resilient to phase-incoherence
        Likelihood = normalize(abs(p), 'norm')'*normalize(abs(NominalGains), 'norm');
        [M,I] = max(Likelihood);
        AoD(ii) = Angles(I);
    end
end