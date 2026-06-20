function p = lt_params()
%LT_PARAMS  Central parameters for the paper-faithful LightThief simulation.
%
%   The model follows LightThief (USENIX Security 2023), Sec. 3.2, 4.4, 5.3:
%     * The OWC light is intensity-modulated (OOK) and Manchester-coded; the
%       light On/Off square wave at the optical clock rate f_o IS the data
%       (Manchester == BPSK, the bit sets the square-wave phase 0 or pi).
%     * That same light square wave switches the LightThief tag's reflection,
%       so the reflected RF is  S_r = S_cw * S_sqw  (paper Eq. 8), placing the
%       data on harmonics at  f_c +/- m*f_o,  m = 1,3,5,...
%     * There is NO separate sub-carrier: the harmonics come from the optical
%       square wave itself, and f_o is the optical clock rate (= bit rate),
%       not a free parameter.
%
%   The RF carrier uses the paper's FM-band experiment frequency (108 MHz).
%   The reflected signal is sampled as SDR-style IQ around that RF center, so
%   fs_rf is an IQ bandwidth / sample rate, not a direct 108 MHz ADC rate.

p.Rb        = 100e3;                 % paper COTS OWC data-rate setting: 100 kbps
p.fo        = p.Rb;                  % optical clock rate / square-wave freq
p.chip_rate = 2 * p.Rb;             % Manchester chip rate: 200 kchips/s

p.fc        = 108e6;                 % FM-band RF carrier used in the paper experiments
p.fc_real   = p.fc;                  % physical link-budget carrier
p.osr       = 24;                    % IQ samples per bit around the RF center
p.fs_rf     = p.osr * p.Rb;         % SDR/IQ sample rate (2.4 MHz)

p.Nb        = 12;                    % baseband samples per bit after harmonic selection
p.fs_bb     = p.Nb * p.Rb;          % baseband sample rate (1.2 MHz)

p.harmonic  = 1;                     % which reflected harmonic the RX selects (m=1: f_c+f_o)

% OWC framing (paper Sec. 6): 8-bit ASCII -> 12-bit Hamming + 1 parity = 13-bit
% codeword -> 26-bit Manchester; 10-bit preamble "1111000010".
p.preamble  = [1 1 1 1 0 0 0 0 1 0];
p.code_len  = 13;                    % bits per Hamming(12,8)+parity codeword
end
