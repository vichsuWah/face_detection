clc
clear all;
close all;

img = double(imread('img\9.jpg'));
subplot(3,3,2), imshow(uint8(img));
skin_mask = img;
[luma, cb, cr] = RGB2YCbCr(skin_mask);

% Mouth_Map
% Luk(a,b) = max(0, a + b - 1)
Cr_2  = Cr .^ 2;
a = Cr_2;
eta = 0.95 * ((sum(Cr.^2, [], 'all')) / (sum(Cr./Cb, [], 'all')));
b = (Cr_2 - eta * Cr ./ Cb) .^ 2;
MouthMap = max(a,b);

% apply smooth filter to eyemap
sigma = 0.5;
[sx, sy] = meshgrid(-2:2, -2:2); % kernel size 5 * 5
smooth_kernel = (1/(2*pi*(sigma^2))) * exp(-1*(sx.^2 + sy.^2) / (2*(sigma^2)));
smooth_MouthMap = filter2(smooth_kernel, MouthMap);

% find local maximum of smooth eyemap
% (i) local maximum   (ii) greater than a threshold
threshold_mouth = 100;
logical_MouthMap = smooth_MouthMap > imdilate(smooth_MouthMap, [1 1 1;1 0 1;1 1 1]);
smooth_MouthMap = smooth_MouthMap .* logical_MouthMap;
smooth_MouthMap(smooth_MouthMap < threshold_mouth) = 0;
% figure(), imshow(smooth_MouthMap, [])

function [Y, Cb, Cr] = RGB2YCbCr(colourimg)
    R = double(colourimg(:, :, 1));
    G = double(colourimg(:, :, 2));
    B = double(colourimg(:, :, 3));
    Y = 0.299 * R + 0.578 * G + 0.114 * B;
    Cb = 0.564 * (B - Y);
    Cr = 0.713 * (R - Y);
end