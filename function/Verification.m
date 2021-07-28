function [flag ,triangle] = Verification(record_E, record_M, record_enorm, record_ellipse)
% initialize return value
flag = false;
triangle = [0 0 0 0 0 0];

[e_n, ~] = size(record_E);
[m_n, ~] = size(record_M);

for eye1 = 1:e_n-1
    for eye2 = eye1+1:e_n
        % (r,c)
        % left_eye & right_eye: record_e(eye1, 1:2) and record_e(eye2, 1:2)
        for mou = 1:m_n
            % mouth: record_m(mou, 1:2)
            % rules: 
            % 1. Mouth is underneath the eyes
            if( record_M(mou, 1) < record_E(eye1, 1) || record_M(mou, 1) < record_E(eye2, 1) )
                1
                continue;
            end
            % 2. The angle between red and purple colored vectors is small
            % red: record_m(mou, 1:2) and mean(record_e([eye1, eye2], 1:2))
            % purple vector: ellipse axis
            u = double(record_M(mou, 1:2)) - mean(record_E([eye1, eye2], 1:2));
            if(record_ellipse(1, 1) > record_ellipse(1,2)) % a > b
                v = record_enorm(1, [2, 1]); % from record_enorm(label, :) | 'e11 e21' e12 e22 |
            else % a <= b
                v = record_enorm(1, [4, 3]); %| e11 e21 'e12 e22' |
            end
            CosTheta = dot(u,v) / (norm(u)*norm(v));
            Theta = acosd(CosTheta);
            if(Theta > 90)
                Theta = 180 - Theta;  % 取補角 
            end 
            if(Theta > 20 || Theta < -20)
                2
                continue;
            end
            
            % 3. The angle between red vector and eye-link line is near 90
            w = double(record_E(eye1, 1:2)) - double(record_E(eye2, 1:2));
            CosTheta = dot(u,w) / (norm(u)*norm(w));
            Theta = acosd(CosTheta) - 90;
            if(Theta > 15 || Theta < -15)
                3
                continue;
            end
            % 4. 三角形底高比，在一定範圍內。
            base = sqrt(w(1,1) ^ 2 + w(1,2) ^ 2);
            height = sqrt(u(1,1) ^ 2 + u(1,2) ^ 2);
            if( 0.8 > height / base || height / base > 1.6 )
                4
                continue;
            end
            
            flag = true;
            triangle = [record_E(eye1, :) record_E(eye2, :) record_M(mou, :)];
            break;
        end
    end
end