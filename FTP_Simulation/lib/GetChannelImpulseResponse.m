function [P_mk, PathToF] = GetChannelImpulseResponse(y, Params)
    P_mk = zeros(size(Params.Multipath, 1), Params.M);
    PathToF = -1*ones(size(Params.Multipath, 1), Params.M);
    for ii=1:Params.M
        % CFO correction
        [xcorr_val, lag] = GuGvXcorr(y(:,ii), Params);
        [M,I] = max(abs(xcorr_val));
    %     figure(2); plot(abs(xcorr_val));
        y_STF = y(lag(I)-length(Params.STF)+[1:length(Params.STF)], ii);
        L = 128;      % Length of single repetition of Ga for SC PHY
        Nreps = 7;   % Number of Ga repetitions to use for CFO estimation
        assert(Params.Fs==1.76e9);
        fOffset = wlan.internal.cfoEstimate(y_STF((1+L):(Nreps*L)), L).*Params.Fs/L;
        y_cfo_removed = y(:, ii).*exp(-1j.*2.*pi.*fOffset./Params.Fs.*[0:size(y,1)-1].');
            
        % extract 128-sample CIR for m-th TX beam
        [xcorr_val, lag] = GuGvXcorr(y_cfo_removed, Params);
        [M,I] = max(abs(xcorr_val));
        CIR_m = xcorr_val((I-1) - (lag(I)-length(Params.STF))+[1:128]);
        %     figure(3); plot(abs(CIR_m));
        MinPeakProminence = 0.3;
        MinPeakHeight = 0.1;
        MinPeakDistance = 1;
        [~,Loc,~,Prominence] = findpeaks(abs(CIR_m)./max(abs(CIR_m)),...
            "MinPeakProminence", MinPeakProminence, "MinPeakHeight", MinPeakHeight, ...
            'MinPeakDistance', MinPeakDistance);
        Loc = sort(Loc);
        P_mk(1:length(Loc), ii) = CIR_m(Loc);
        PathToF(1:length(Loc), ii) = Loc;
    end
end