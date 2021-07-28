clc
clear all;
close all;

a = double(175.2893); % x¶b
b = double(259.0107); % y¶b
r = round(max(a,b));
m = [-0.9959 -0.0910;-0.0910 0.9959];
[X,Y] = meshgrid(-r:r, -r:r);
X_new = X * m(1,1) + Y * m(2,1);
Y_new = X * m(1,2) + Y * m(2,2);
ellipse = ones(2*r+1, 2*r+1); % (2*r+1) * (2*r+1)
logical = ((X_new.^2 / a^2 + Y_new.^2 / b^2) < 1);
ellipse = ellipse .* logical;
figure(), imshow(ellipse, []);