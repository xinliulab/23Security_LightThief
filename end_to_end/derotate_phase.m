function out = derotate_phase(sym)
%DEROTATE_PHASE  Remove the static BPSK carrier phase (theta = 0.5*angle(E[sym^2])).
%   Squaring strips the +/-1 modulation so the mean angle of sym^2 is twice the
%   carrier phase.  Pre-aligns the constellation to the real axis so the Costas
%   loop starts inside its lock range (it fails when the residual phase is near
%   +/-45 deg).  The remaining pi ambiguity is resolved by the preamble.

theta = 0.5 * angle(mean(sym .^ 2));
out = sym .* exp(-1j * theta);
end
