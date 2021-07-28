clc
clear all;
close all;

addpath('./gabor-master/');

img = double(imread('img\9.jpg'));
subplot(3,3,2), imshow(uint8(img));
[luma, cb, cr] = RGB2YCbCr(img);
%subplot(2,3,2), imshow(uint8(luma));

% eyemap l
se = strel('diamond', 1);
eroded = imerode(luma, se);
%subplot(2,3,3), imshow(uint8(eroded));
eyemap_l = (-1 * eroded + 255) / 255;
subplot(3,3,4), imshow(eyemap_l)

% eyemap c
cb = cb + 127.5;
cr = cr + 127.5;
cr_hat = max(cr, [], 'all') - cr;
eyemap_c = (1/3) * (cb.^2 + cr_hat.^2 + (cb./cr));
eyemap_c(isinf(eyemap_c)) = (255);
eyemap_c(isnan(eyemap_c)) = 0;
%eyemap_c = (eyemap_c / max(eyemap_c, [], 'all')) * 255;
subplot(3,3,5), imshow(eyemap_c, [])

% eyemap t
gaborArray = gaborFilterBank(2,4,39,39);
[featureVector, max_eyemapT] = gaborFeatures(luma,gaborArray,4,4);
subplot(3,3,6), imshow(abs(max_eyemapT),[])
%imshow(I,[]) displays the grayscale image I, scaling the display based on the range of pixel values in I. imshow uses [min(I(:)) max(I(:))] as the display range. imshow displays the minimum value in I as black and the maximum value as white. For more information, see the DisplayRange parameter.
eyemap_t = abs(max_eyemapT);

% eyemap_l & eyemap_c & eyemap_t need normalized [ mean = 0 and variance = 1 ]
eyemap_l = eyemap_l-mean(eyemap_l(:));
eyemap_l = eyemap_l/std(eyemap_l(:), 0, 1);

eyemap_c = eyemap_c-mean(eyemap_c(:));
eyemap_c = eyemap_c/std(eyemap_c(:), 0, 1);

eyemap_t = eyemap_t-mean(eyemap_t(:));
eyemap_t = eyemap_t/std(eyemap_t(:), 0, 1);

w1 = 0.2;
w2 = 0.5;
w3 = 0.3;
eyemap = w1 * eyemap_l + w2 * eyemap_c + w3 * eyemap_t;
C = 100;
eyemap = eyemap * C;
subplot(3,3,8), imshow(eyemap, []);

% apply smooth filter to eyemap
sigma = 0.5;
[sx, sy] = meshgrid(-2:2, -2:2); % kernel size 5 * 5
smooth_kernel = (1/(2*pi*(sigma^2))) * exp(-1*(sx.^2 + sy.^2) / (2*(sigma^2)));
smooth_eyemap = filter2(smooth_kernel, eyemap);
subplot(3,3,9), imshow(smooth_eyemap, []);

% find local maximum of smooth eyemap
% (i) local maximum   (ii) greater than a threshold
threshold_eye = 100;
logical_eyemap = smooth_eyemap > imdilate(smooth_eyemap, [1 1 1;1 0 1;1 1 1]);
smooth_eyemap = smooth_eyemap .* logical_eyemap;
smooth_eyemap(smooth_eyemap < threshold_eye) = 0;
figure(), imshow(smooth_eyemap, [])
1

function [Y, Cb, Cr] = RGB2YCbCr(colourimg)
    R = double(colourimg(:, :, 1));
    G = double(colourimg(:, :, 2));
    B = double(colourimg(:, :, 3));
    Y = 0.299 * R + 0.578 * G + 0.114 * B;
    Cb = 0.564 * (B - Y);
    Cr = 0.713 * (R - Y);
end

% https://github.com/mhaghighat/gabor
% https://www.mathworks.com/matlabcentral/fileexchange/59500-gabor-wavelets