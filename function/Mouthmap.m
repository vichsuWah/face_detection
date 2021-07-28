function record = Mouthmap(img, skin_mask)
% record central point of mouth candidates
[m, n, ~] = size(img);

[~, cb, cr] = RGB2YCbCr(img .* skin_mask);
cb = cb + 127.5;
cr = cr + 127.5;
cr_2  = cr .^ 2;
eta = 0.95 * ((sum(cr.^2, 'all')) / (sum(cr./cb, 'all')));
first = cr_2;
second = (cr_2 - eta * cr ./ cb) .^ 2;
MouthMap = max(first,second);
figure(), subplot(3,1,1), imshow(MouthMap, []); 

% Smooth filter
sigma = 0.5;
[sx, sy] = meshgrid(-2:2, -2:2); % kernel size 5 * 5
smooth_kernel = (1/(2*pi*(sigma^2))) * exp(-1*(sx.^2 + sy.^2) / (2*(sigma^2)));
smooth_MouthMap = filter2(smooth_kernel, MouthMap);
subplot(3,1,2), imshow(smooth_MouthMap, []);

% range (max~min) to (0~255)
mm_interval = max(smooth_MouthMap, [], 'all') - min(smooth_MouthMap, [], 'all');
smooth_MouthMap = ( smooth_MouthMap - min(smooth_MouthMap, [], 'all') ) * 255 / mm_interval;

% find local maximum of smooth mouthmap
% (i) local maximum   (ii) greater than a threshold
maxm_v = max(smooth_MouthMap, [], 'all');
threshold_mouth = (0.8)*maxm_v;
logical_MouthMap = smooth_MouthMap > imdilate(smooth_MouthMap, [1 1 1;1 0 1;1 1 1]);
smooth_MouthMap = smooth_MouthMap .* logical_MouthMap;
smooth_MouthMap(smooth_MouthMap < threshold_mouth) = 0;
smooth_MouthMap = imdilate(smooth_MouthMap, strel('disk', 10));
subplot(3,1,3), imshow(smooth_MouthMap, []);

[mp, m_n] = bwlabel(smooth_MouthMap);
record_m = zeros(m_n, 2);          % record mouth central point (r, c)
for i  = 1 : m_n
    %[M, N] = size(mouthmap);         % m -> row, n -> column
    maxis = find(mp == i) - 1;  % find -> (r,c) : r + M * (c-1)
    maxis_r = mod(maxis, m);          % row
    maxis_c = (maxis - maxis_r) / m;  % column
    mmat = [maxis_r + 1, maxis_c + 1];
    record_m(i, 1:2) = mean(mmat);    % mouth_candidate: (central_r, central_c)
end
record_m = int16(record_m);

% record central point of mouth candidates
record = record_m;