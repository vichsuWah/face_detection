function y = Estimate_R(img, label, flag)

% find the axis of points in the 'label'_th region
[M, N] = size(img);                 % M -> row, N -> column
if(flag)
    axis = find(img == 1) - 1;
else
    axis = find(img == label) - 1;  % find -> (r,c) : r + M * (c-1)
end
axis_r = mod(axis, M);              % row
axis_c = (axis - axis_r) / M;       % column
mat = [axis_c + 1, axis_r + 1];
xy = mat - mean(mat);
z = transpose(xy) * xy;
% z is a 2*2 matrix
[E, ~] = eig(z);
% E -> eigenvectors and D -> eigenvalues
% E need normalize : (1/sqrt(a^2 + b^2)) * (a, b)
E_norm = E .* [( 1/sqrt(E(1, 1)^2 + E(2, 1)^2) ), ( 1/sqrt(E(1, 2)^2 + E(2, 2)^2) )];

% coordinate transformation
xy_new = xy * E_norm;
% (eq.84) x1 = column(x_axis),  x2 = row(y_axis)
%         m11 = E(| x1 |)       m12 = E(| x2 |)   
%         m21 = E(| x1 | ^ 2)   m22 = E(| x2 | ^ 2)
m1= mean(abs(xy_new));  % m1 = [ m11 m12 ]
m2 = mean(xy_new .^ 2); % m2 = [ m21 m22 ]
a1 = 3*pi*m1(1,1)/4;
b1 = 3*pi*m1(1,2)/4;
a2 = sqrt(4*m2(1,1));
b2 = sqrt(4*m2(1,2));
a = (a1 + a2)/2;
b = (b1 + b2)/2;

% record ellipse
global record_enorm;
global record_ellipse;

if(flag)
    record_enorm(label, 1:4) = [E_norm(1,1), E_norm(2,1), E_norm(1,2), E_norm(2,2)];
    record_ellipse(label, 1:4) = [a, b, mean(mat(:, 2)), mean(mat(:, 1))]; % a b center_col center_row
end

% condition (ii): 1/3 < a/b < 3
if a/b >=3 || a/b <= 1/3
    disp('condition 1')
    % not face
    img(img == label) = 0;
% condition (i): Xnew^2 / a^2 + Ynew^2 / b^2 <= 1 (<-prt)
else
    disp('condition 2')
    [e_X, e_Y] = meshgrid( int16(-(a+1)):int16(a+1), int16(-(b+1)):int16(b+1) );
    eX = double(e_X.^2) ./ (a^2);
    eY = double(e_Y.^2) ./ (b^2);
    ellipse_area = sum( (eX + eY) <= 1, 'all' );
    skin_in_ell_Area = sum( ( (xy_new .^ 2) * [1/(a^2) ; 1/(b^2)] ) <= 1, 'all' );
    percent = skin_in_ell_Area / ellipse_area;
    disp("label:"+label+"  percent:"+percent)

    % debug: print ellipse(coordinate transformation)
    central = mean(mat);        % mat : [col(x), row(y)]
    cX = round(central(1));     % central_X
    cY = round(central(2));     % central_Y
    r = round(max(a,b));        % r : radius
    cX_0 = cX - r;
    cX_1 = cX + r;
    % boundary condition
    if(cX_0<1)
        cX_0 = 1;
    end
    if(cX_1>N)
        cX_1 = N;
    end
    cY_0 = cY - r;
    cY_1 = cY + r;
    if(cY_0<1)
        cY_0 = 1;
    end
    if(cY_1>M)
        cY_1 = M;
    end

    [draw_X, draw_Y] = meshgrid(-r:r, -r:r);
    inv_E = inv(E_norm);
    draw_eX = inv_E(1,1) * draw_X + inv_E(2,1) * draw_Y;
    draw_eY = inv_E(1,2) * draw_X + inv_E(2,2) * draw_Y;
    draw_logical = (draw_eX .^ 2 / a^2 + draw_eY .^ 2 / b^2 < 0.7); % skin_mask for EyeMap
    draw_ellipse = zeros(M, N);
    %draw_ellipse(cY_0:cY_1, cX_0:cX_1) = draw_ellipse(cY_0:cY_1, cX_0:cX_1) + draw_logical(cY_0-cY+(r+1):cY_1-cY+(r+1), cX_0-cX+(r+1):cX_1-cX+(r+1));
    draw_ellipse(cY_0:cY_1, cX_0:cX_1) = draw_logical( (r+1)-(cY-cY_0) : (r+1)+(cY_1-cY), (r+1)-(cX-cX_0) : (r+1)+(cX_1-cX) );
    %figure(), imshow(draw_ellipse, []);
    %
    % 0.67
    if percent < 0.6
        img(img==label) = 0;
    elseif(flag)
        %img = img .* draw_ellipse;
        img = or(img, draw_ellipse);
    end
end
y = img;
