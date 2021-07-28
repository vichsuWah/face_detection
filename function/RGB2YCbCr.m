function [Y, Cb, Cr] = RGB2YCbCr(colourimg)
R = double(colourimg(:, :, 1));
G = double(colourimg(:, :, 2));
B = double(colourimg(:, :, 3));
Y = 0.299 * R + 0.578 * G + 0.114 * B;
Cb = 0.564 * (B - Y);
Cr = 0.713 * (R - Y);
