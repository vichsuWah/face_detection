clear all;
close all;
clc

%% training a SVM Model
% 輸入 LIBSVM (Matlab version) 所在的資料夾
addpath('C:\Program Files\MATLAB\R2019a\toolbox\libsvm-3.24\matlab');
addpath('./gabor-master/');
addpath('./function');

% 1. Read skin & non-skin pixel(rgb) from file / Testing Data
skin = textread("data\skin_rgb.txt");
non_skin = textread("data\non-skin_rgb.txt");

% 2. Convert RGB to YCbCr
skin_ycbcr = YCbCr(skin);
non_skin_ycbcr = YCbCr(non_skin);

% 3. Training Data (1: skin / 0: non-skin)
X = [skin_ycbcr; non_skin_ycbcr];
y = [ones(size(skin_ycbcr, 1), 1); zeros(size(non_skin_ycbcr, 1), 1)];

% 4. Normalization
mf=mean(X);
nrm=diag(1./std(X,1));
X = (X - ones(size(X, 1), 1)*mf)*nrm;

% 5. SVM Model
%SVMModel = fitcsvm(X,y);
model = svmtrain(y, X, '-s 0 -t 2 -c 1.2 -g 2.8');
%SVMModel = fitcsvm(X, y,'KernelFunction','rbf','OptimizeHyperparameters',{'BoxConstraint','KernelScale'},  'HyperparameterOptimizationOptions',struct('ShowPlots',false));
%svm_3d_plot(SVMModel,X, y);

%% input an image to SVM model
% 6. Testing
%for no = [8, 9, 16, 22, 26, 28, 30, 55, 59, 68, 70, 78]
for no = [1,2,3]    
    img = double( imread( ['img\TestImagesForPrograms\' num2str(no) '.jpg'] ) );
    figure(1), subplot(2, 2, 1), imshow(uint8(img));
    [m, n, ~] = size(img);
    test_data = YCbCr(reshape(img, m * n, 3));
    test_label = zeros(size(test_data, 1), 1);
    test_data = (test_data - ones(size(test_data, 1), 1)*mf)*nrm;

    [predicted, ~, ~] = svmpredict(test_label, test_data, model);
    detect = reshape(predicted, m, n);
    subplot(2, 2, 2), imshow(detect);

    % 7. Morphology ( about min(M, N)/100 times )
    se = strel('disk',5);
    for times = 1 : max(m, n)
        detect = imopen(detect,se);
        detect = imclose(detect,se);
    end
    subplot(2, 2, 3), imshow(detect);
    
    % 11_12 DO SOMETHING
    [Gmag, Gdir] = imgradient(rgb2gray(uint8(img)),'prewitt');
    Gmax = max(Gmag, [], 'all');
    Gmin = min(Gmag, [], 'all');
    Gmag = 255 * double(Gmag - Gmin) / double(Gmax - Gmin);
    % *
    Gmag = medfilt2(Gmag > 30);
    % *
    Edge = edge(Gmag, 'Roberts');
    se = strel('line',25,90);
    eg = imclose(Edge, se);
    eg = imdilate(eg, strel('disk', 3));
    [bw, ~] = bwlabel(xor(eg, detect));
    % 
    
    % 8. Label connected: bwlabel & Estimating Ellipse
    %[BW, num] = bwlabel(detect);
    [BW, num] = bwlabel(and(bw, detect));
    
    % *
    se = strel('disk', 5);
    for times = 1 : max(m, n)
        BW = imopen(BW,se);
        BW = imclose(BW,se);
    end
    BW = imdilate(BW, strel('diamond', 3));
    % *
    [BW, num] = bwlabel(BW);
    % global variable record ellipse
    global record_enorm;
    global record_ellipse;
    
    record_enorm = zeros(num, 4); % e11 e21 e12 e22
    record_ellipse = zeros(num, 4); % a b center_row center_col
    % ------------------------
    
    Eyemap_SM = BW;
    for i = 1: num
        areaofRegion = sum(sum(BW==i));
        if areaofRegion < (m*n/700)
            % the region is removed
            BW(BW==i) = 0;
        else
            % estimating satisfy ellipse or not
            BW = Estimate_R(BW, i, false);
        end
    end
    subplot(2, 2, 4), imshow(BW);
    
    BW = imclose(BW, strel('disk', 40));
    [BW, num] = bwlabel(BW);
    figure(), imshow(BW);
    
    % variance of color detection (BW region)
    
    %
    
    record_draw = zeros(num, 7); % label: flag + triangle(number:eye1 eye2 mouth)
    % check each label region [eyemap and mouthmap]
    for i = 1:num
        % mask = (BW == i) <original ver.>
        mask = (BW == i);
        skin_mask = Estimate_R(mask, i, true);
        skin_mask = imclose(skin_mask, strel('disk',40)); % skin_mask need closing
        record_E = Eyemap(img, skin_mask);      % return the candidates of eyes' (r,c)
        record_M = Mouthmap(img, skin_mask);    % retunr the candidates of mouthes' (r,c)

        [face_flag, triangle] = Verification(record_E, record_M, record_enorm(i, :), record_ellipse(i, :));

        if(face_flag)
            % pass the Verficiation
            record_draw(i, :) = [face_flag, triangle];
        end
    end

    % draw the detection face on image
    figure(), imshow(uint8(img));
    hold on
    t=0:0.1:2*pi;
    % using record_draw
    for i = 1:num
        if(record_draw(i, 1))
            % draw ellipse
            % record_ellipse(i, 1:4) = a b center_col center_row
            radio_a = record_ellipse(i, 1);
            radio_b = record_ellipse(i, 2);
            x_o = record_ellipse(i, 4);
            y_o = record_ellipse(i, 3);
            % record_enorm(i, 1:4) = [E_norm(1,1), E_norm(2,1), E_norm(1,2), E_norm(2,2)];
            transpose_mat = [record_enorm(i, 1) record_enorm(i, 3); record_enorm(i, 2) record_enorm(i, 4)];
            x = radio_a*sin(t);
            y = radio_b*cos(t);
            xy  = [x', y'] * transpose_mat + [x_o, y_o];
            plot(xy(:, 1)',xy(:, 2)','r');

            % draw triangle: "record_draw(num, :) = [face_flag, triangle]"
            % eye1: record_draw(i, 2:3)
            % eye2: record_draw(i, 4:5)
            % mouth: record_draw(i, 6:7)
            line([record_draw(i, 3), record_draw(i, 5)], [record_draw(i, 2), record_draw(i, 4)]);   % eye1 eye2
            line([record_draw(i, 3), record_draw(i, 7)], [record_draw(i, 2), record_draw(i, 6)]);   % eye1 mouth
            line([record_draw(i, 5), record_draw(i, 7)], [record_draw(i, 4), record_draw(i, 6)]);   % eye2 mouth
        end
    end
    hold off
    % finish detection
    disp(no)
    close all
end