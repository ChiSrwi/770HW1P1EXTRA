clear
dat = dlmread('/Users/tonyqisirui/Downloads/51_50_2.txt');
t = dat(:,1);
x = dat(:,2);
y = dat(:,3);
z = dat(:,4);

t = t-t(1);

% t = t(length(t)/2:end);

magnitude = sqrt(x.^2 + y.^2 + z.^2);
% magnitude = magnitude(length(magnitude)/2:end);
Fs = 25;
Fc = 3;
windowSize = 8;
% Peakwin = 100;
min_peak_height = 0.0;  
min_peak_distance = 10;

magnitude = magnitude - mean(magnitude); 

% points_per_segment = 60;
% num_segments = floor(length(magnitude) / points_per_segment);
% mean_magnitude = zeros(1, num_segments);
% mean_time = zeros(1, num_segments);
% for i = 1:num_segments
%     segment_start = (i-1)*points_per_segment + 1;
%     segment_end = i*points_per_segment;
%     mean_magnitude(i) = mean(magnitude(segment_start:segment_end));
%     mean_time(i) = mean(t(segment_start:segment_end));
% end
% 
% figure;
% plot(t, magnitude, 'g', 'LineWidth', 0.5); hold on;
% plot(mean_time, mean_magnitude, 'ro-', 'LineWidth', 1.5); 
% xlabel('Time');
% ylabel('Magnitude');
% grid on;
% title('Magnitude and 60-Point Mean Magnitude');



[bb, aa] = butter(6, Fc/(Fs/2), 'low');
disp(bb)
disp(aa)
b = [0.0009, 0.0051, 0.0129, 0.0172, 0.0129, 0.0051, 0.0009];
a = [1.0000, -3.0985, 4.4164, -3.5566, 1.6851, -0.4411, 0.0496];
smoothed_magnitude = filtfilt(b, a, magnitude);
smoothed_magnitude = movmean(smoothed_magnitude, windowSize);


[peaks, locs] = findpeaks(smoothed_magnitude, 'MinPeakHeight', min_peak_height, 'MinPeakDistance', min_peak_distance);

% [peaks, locs] = findpeaks(smoothed_magnitude, 'MinPeakDistance', min_peak_distance);


step_count = length(peaks);

% step_count = 0;
% steps = [];
% for i = 1:Peakwin:length(smoothed_magnitude)-Peakwin
%     window = smoothed_magnitude(i:i+Peakwin-1);
%     [peaks, locs] = findpeaks(window, 'MinPeakHeight', min_peak_height, 'MinPeakDistance', min_peak_distance);
% 
%     step_count = step_count + length(peaks);
%     steps = [steps; t(i + locs - 1)];  
% end


% [peaks, locs] = findpeaks(smoothed_magnitude, 'MinPeakDistance', Peakwin);


% zci = @(v) find(v(:).*circshift(v(:), 1, 1) <= 0); 
% zero_crossings = zci(smoothed_magnitude); 
% 
% num_steps = length(zero_crossings) / 2;

% disp(['Steps: ', step_count]);

fprintf('Steps: %d\n', step_count);

figure;
plot(t, magnitude, 'g', 'LineWidth', 0.5); hold on;
plot(t, smoothed_magnitude, 'b', 'LineWidth', 1.5); hold on;
plot(t(locs), peaks, 'r*', 'MarkerSize', 8);
% plot(steps, interp1(t, smoothed_magnitude, steps), 'ro', 'MarkerSize', 10);
xlabel('Time');
ylabel('Magnitude');
grid on;
