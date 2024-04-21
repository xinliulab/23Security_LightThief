function [rate, mcs] = get_11ad_datarate(snr_matrix)
%     assert(length(sensitivity)<=1 || iscolumn(sensitivity));
    load("PER_TABLE.mat");
    shift = 10*log10((1760e6/200e6));
%     PER_TABLE = circshift(PER_TABLE,shift,2);
    snr_points = [0:0.5:30];
    rate_11ad = 1e6*[385,770,962.5,1155,1251.3,1540,1925,2310,2502.5,3080,3850,4620]; %MCS 1-12
    snrs = snr_matrix(:)-3;
    rate = zeros(length(snrs),1);
    mcs = zeros(length(snrs),1);
    for ii=1:length(snrs)
        col_idx = find(snrs(ii)>=snr_points,1,'last');
        if ~isempty(col_idx)
            per = PER_TABLE(:,col_idx).';
            [M,I] = max(rate_11ad.*(1-per));
            mcs(ii) = I;
            rate(ii) = M;
        else
            mcs(ii) = 1;
            rate(ii) = 0;
        end
    end
    mcs = reshape(mcs, size(snr_matrix));
    rate = reshape(rate, size(snr_matrix));
    %     rate_11ad = 1e6*[27.5,385,770,962.5,1155,1251.3,1540,1925,2310,2502.5,3080,3850,4620];
%     sensitivity_tbl = [-78,-68,-66,-65,-64,-62,-63,-62,-61,-59,-55,-54,-53];
%     [C,I] = max((sensitivity(:)>=sensitivity_tbl).*rate_11ad, [], 2);
%     rate = reshape(C, size(sensitivity));
%     mcs = reshape(I-1, size(sensitivity));
end

