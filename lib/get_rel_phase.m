function [rel_phase,rel_phase_avg,rel_phase_std] = get_rel_phase(rx_pwr)
    % rx_pwr in shape (measurements, iteration)
    [n, iters] = size(rx_pwr);
    assert(mod(n,4)==0, "get_rel_phase sanity1");
    rx_pwr = reshape(rx_pwr,4,n/4,iters);
    FFT_X = fft(rx_pwr ,[], 1);
    rel_phase = squeeze(angle(FFT_X(2,:,:))); % (ant, iteration)
    if iters<=1
        rel_phase = rel_phase.';
        assert(iscolumn(rel_phase));
        rel_phase_avg = rel_phase; % (ant, )
        rel_phase_std = zeros(length(rel_phase_avg),1); % (ant, )
    else
%         rel_phase = unwrap(rel_phase,[],2);
        rel_phase_avg = angle(mean(exp(1j*rel_phase), 2)); % (ant, )
        rel_phase_std = std(rel_phase, 0, 2); % (ant, )
    end
end