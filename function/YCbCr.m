function y = YCbCr(x)

% matrix multiply
convertMat = [0.257 -0.148 0.439; 0.564 -0.291 -0.368; 0.098 0.439 -0.071];
bias = [16 128 128];
y = x * convertMat + bias;

y(y>255) = 255;
y(y<0) = 0;
