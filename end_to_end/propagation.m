function info = propagation(p, geom)
%PROPAGATION  3-D physical-wave link budget for LightThief (paper Eq. 1, 4, 6).
%
%   Both the optical and the RF signals are three-dimensional waves that spread
%   over a sphere, so their power density falls as 1/(4*pi*d^2).  This function
%   makes that explicit and turns the geometry into an operating SNR for the
%   decoder, instead of hand-picking an SNR.
%
%   geom fields (all optional, sensible defaults below):
%     d_ph  LED -> tag distance        (m)   -> incident optical power (Eq. 4)
%     d_t   RF TX -> tag distance       (m)   -> CW power at the tag   (Eq. 1, term 1)
%     d_r   tag -> attacker distance    (m)   -> power at the RX       (Eq. 1, term 3)
%
%   Returns a struct with the per-segment terms, the received signal strength
%   RSS (dBm), and a derived snr_db that run_demo / channel_apply can use.

if nargin < 2, geom = struct(); end
d_ph = getfielddef(geom, 'd_ph', 0.3);     % m, LED -> tag
d_t  = getfielddef(geom, 'd_t', 1.0);      % m, RF TX -> tag
d_r  = getfielddef(geom, 'd_r', 10.0);     % m, tag -> attacker (through the wall)

c       = 3e8;
lambda  = c / p.fc_real;            % RF wavelength at the true 108 MHz carrier
% --- Optical side: incident photocurrent, 3-D spreading of the light (Eq. 4) ---
Rlambda = 0.5;                      % PD responsivity (A/W), representative
P_opt   = 1e-3;                     % radiated optical power (W)
Iph     = Rlambda * P_opt / (4 * pi * d_ph^2);     % 1/(4*pi*d^2): spherical light wave

% --- Backscatter contrast: two PD impedance states (Eq. 6 -> Eq. 2/3) ----------
% Larger photocurrent -> smaller "on" impedance -> larger reflection contrast.
dGamma2 = (Iph / (Iph + 1e-6))^2;   % normalized backscatter coefficient |dGamma|^2 in [0,1)

% --- RF side: 3-segment Friis backscatter link (Eq. 1), each a 3-D wave ---------
Pt = 0.1; Gt = 1; Gr = 1; Gpassive = 1; alpha = 0.5;   % representative
forward   = Pt * Gt / (4 * pi * d_t^2);                          % TX -> tag
reflect   = Gpassive^2 * dGamma2 / 4 * alpha * (lambda^2 / (4 * pi)); % tag reflection
backward  = Gr / (4 * pi * d_r^2);                              % tag -> attacker
Pr = forward * reflect * backward;                              % received power (W)

RSS_dBm = 10 * log10(Pr / 1e-3 + eps);
noise_dBm = -90;                                                % representative noise floor
snr_db = max(RSS_dBm - noise_dBm, 0);

info = struct('d_ph', d_ph, 'd_t', d_t, 'd_r', d_r, 'Iph', Iph, ...
    'dGamma2', dGamma2, 'RSS_dBm', RSS_dBm, 'snr_db', snr_db, ...
    'forward', forward, 'reflect', reflect, 'backward', backward);
end


function v = getfielddef(s, f, d)
if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end
