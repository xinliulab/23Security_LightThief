function average_power_db = readSignalStrength(filename)    

fid = fopen(filename, 'r');
rawData = fread(fid, [2, inf], 'float32');
fclose(fid);
rxWaveform = 0.32*complex(rawData(1, :), rawData(2, :));

Fs = 1600000;
bandwidth = 400000; % bandwidth of interest in Hz
lpFilt = designfilt('lowpassfir', 'PassbandFrequency', bandwidth/2, ...
                    'StopbandFrequency', bandwidth, 'PassbandRipple', 1, ...
                    'StopbandAttenuation', 60, 'SampleRate', Fs);
filtered_waveform = filter(lpFilt, rxWaveform);
average_power = mean(abs(filtered_waveform).^2);
average_power_db = 10*log10(average_power);
disp(average_power_db);

end

