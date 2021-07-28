function record = Eyemap(img, skin_mask)
% record central point of eye candidates
[m, n, ~] = size(img);
[luma, cb, cr] = RGB2YCbCr(img);

% eyemap l
eroded = imerode(luma, strel('diamond', 1));
eyemap_l = (-1 * eroded + 255) / 255;
figure(), subplot(3,3,1), imshow(eyemap_l)

% eyemap c
cb = cb + 127.5;
cr = cr + 127.5;
cr_hat = max(cr, [], 'all') - cr;
eyemap_c = (1/3) * (cb.^2 + cr_hat.^2 + (cb./cr));
eyemap_c(isinf(eyemap_c)) = (255);
eyemap_c(isnan(eyemap_c)) = 0;
subplot(3,3,2), imshow(eyemap_c, [])

% eyemap t
gaborArray = gaborFilterBank(2,4,39,39);
[~, max_eyemapT] = gaborFeatures(luma,gaborArray,4,4);
subplot(3,3,3), imshow(abs(max_eyemapT),[])
eyemap_t = abs(max_eyemapT);

% eyemap_l & eyemap_c & eyemap_t need normalized [ mean = 0 and variance = 1 ]
eyemap_l = eyemap_l-mean(eyemap_l(:));
eyemap_l = eyemap_l/std(eyemap_l(:), 0, 1);

eyemap_c = eyemap_c-mean(eyemap_c(:));
eyemap_c = eyemap_c/std(eyemap_c(:), 0, 1);

eyemap_t = eyemap_t-mean(eyemap_t(:));
eyemap_t = eyemap_t/std(eyemap_t(:), 0, 1);

w1 = 0.5;
w2 = 0.3;
w3 = 0.2;

eyemap = w1 * eyemap_l + w2 * eyemap_c + w3 * eyemap_t;
C = 100;
eyemap = eyemap * C;
eyemap(isnan(eyemap)) = 0;
subplot(3,3,4), imshow(eyemap, []);

% apply smooth filter to eyemap
sigma = 0.5;
[sx, sy] = meshgrid(-2:2, -2:2); % kernel size 5 * 5
smooth_kernel = (1/(2*pi*(sigma^2))) * exp(-1*(sx.^2 + sy.^2) / (2*(sigma^2)));
smooth_eyemap = filter2(smooth_kernel, eyemap);
subplot(3,3,5), imshow(smooth_eyemap, []);

% find local maximum of smooth eyemap
% (i) local maximum   (ii) greater than a threshold
% apply skin mask to Eyemap
smooth_eyemap = smooth_eyemap .* skin_mask;
subplot(3,3,6), imshow(smooth_eyemap, []);
maxe_v = max(smooth_eyemap, [], 'all');
threshold_eye = (0.65)*maxe_v;
logical_eyemap = smooth_eyemap > imdilate(smooth_eyemap, [1 1 1;1 0 1;1 1 1]);
smooth_eyemap = smooth_eyemap .* logical_eyemap;
smooth_eyemap(smooth_eyemap < threshold_eye) = 0;
% too small to see eyes , so do img dilation
smooth_eyemap = imdilate(smooth_eyemap, strel('disk', 10));
subplot(3,3,8), imshow(smooth_eyemap, [])

[ep, e_n] = bwlabel(smooth_eyemap);
record_e = zeros(e_n, 2);
for i = 1 : e_n
    eaxis = find(ep == i) - 1;          % find -> (r,c) : r + M * (c-1)
    eaxis_r = mod(eaxis, m);            % row
    eaxis_c = (eaxis - eaxis_r) / m;    % column
    emat = [eaxis_r + 1, eaxis_c + 1];
    record_e(i, 1:2) = mean(emat);      % eye_candidate: (central_r, central_c)
end
record_e = int16(record_e);

% record central point of eye candidates
record = record_e;
