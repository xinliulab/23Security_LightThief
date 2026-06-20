function run_sine_reflection_demo()
%RUN_SINE_REFLECTION_DEMO  Visualize switching modulation of a sine carrier.
%
% A simplified LightThief insight model:
%   reflected(t) = incident_carrier(t) .* tag_switch(t)
%
% A zero-mean square-wave switching coefficient translates the carrier onto
% odd harmonics at fc +/- k*ftag, k = 1, 3, 5, ...
%
% This is a simulation-only physical insight demo. It does not load measured
% data or implement a hardware interface.

fs = 240e6;
duration = 2e-3;
fc = 108e6;
ftag = 100e3;

t = (0:round(duration * fs) - 1) / fs;
incident = cos(2 * pi * fc * t);
tag_switch = sign(sin(2 * pi * ftag * t));
tag_switch(tag_switch == 0) = 1;
reflected = incident .* tag_switch;

nfft = 2 ^ nextpow2(numel(reflected));
spectrum = abs(fft(reflected, nfft));
spectrum = spectrum(1:nfft / 2 + 1);
spectrum = spectrum / max(spectrum);
spectrum_db = 20 * log10(spectrum + 1e-12);
frequency = (0:nfft / 2) * fs / nfft;

fig = figure('Position', [100 100 900 700], 'Color', 'w');

view_samples = 1:min(round(8 / ftag * fs), numel(t));

subplot(3, 1, 1);
plot(t(view_samples) * 1e6, incident(view_samples), 'LineWidth', 1.1);
grid on;
xlabel('Time (\mus)');
ylabel('Amplitude');
title(sprintf('Incident sinusoidal carrier, f_c = %.2f MHz', fc / 1e6));

subplot(3, 1, 2);
plot(t(view_samples) * 1e6, tag_switch(view_samples), 'LineWidth', 1.1);
grid on;
ylim([-1.3 1.3]);
xlabel('Time (\mus)');
ylabel('Reflection state');
title(sprintf('Tag switching coefficient, f_{tag} = %.0f kHz', ftag / 1e3));

subplot(3, 1, 3);
plot(frequency / 1e6, spectrum_db, 'LineWidth', 1.1);
grid on;
xlim([max(0, (fc - 6 * ftag) / 1e6), min(fs / 2e6, (fc + 6 * ftag) / 1e6)]);
ylim([-80 5]);
xlabel('Frequency (MHz)');
ylabel('Normalized magnitude (dB)');
title('Reflected spectrum: components at f_c \pm k f_{tag}, odd k');
hold on;
for k = [1 3 5]
    lower = fc - k * ftag;
    upper = fc + k * ftag;
    if lower > 0
        xline(lower / 1e6, 'r--');
    end
    if upper < fs / 2
        xline(upper / 1e6, 'r--');
    end
end

figure_dir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(figure_dir, 'dir')
    mkdir(figure_dir);
end
output_file = fullfile(figure_dir, 'sine_reflection_spectrum.png');
saveas(fig, output_file);

fprintf('Incident carrier: %.2f MHz\n', fc / 1e6);
fprintf('Tag switching rate: %.0f kHz\n', ftag / 1e3);
fprintf('Expected sidebands: fc +/- k*ftag for odd k\n');
fprintf('Figure written to %s\n', output_file);
end
