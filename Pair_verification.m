%% Eye-Mouth Pairs Verification
% smooth_MouthMap & smooth_eyemap
% record central point of mouth and eye candidate
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
[ep, e_n] = bwlabel(smooth_eyemap);
record_e = zeros(e_n, 2);
for i = 1 : e_n
    eaxis = find(ep == i) - 1;          % find -> (r,c) : r + M * (c-1)
    eaxis_r = mod(eaxis, m);            % row
    eaxis_c = (eaxis - eaxis_r) / m;    % column
    emat = [eaxis_r + 1, eaxis_c + 1];
    record_e(i, 1:2) = mean(emat);      % eye_candidate: (central_r, central_c)
end
1

for eye1 = 1:e_n-1
    for eye2 = e1:e_n
        % (r,c)
        % left_eye & right_eye: record_e(eye1, 1:2) and record_e(eye2, 1:2)
        for mou = 1:m_n
            % mouth: record_m(mou, 1:2)
            % rules: 
            % 1. Mouth is underneath the eyes
            if( record_m(mou, 1) < record_e(eye1, 1) || record_m(mou, 1) < record_e(eye2, 1) )
                continue;
            end
            % 2. The angle between red and purple colored vectors is small
            % red: record_m(mou, 1:2) and mean(record_e([eye1, eye2], 1:2))
            u = record_m(mou, 1:2);
            v = mean(record_e([eye1, eye2], 1:2));
            CosTheta = dot(u,v) / (norm(u)*norm(v));
            Theta = acosd(CosTheta);
            % purple vector:
            
            % 3. The angle between red vector and eye-link line is near 90
            
            % 4. 三角形底高比，在一定範圍內。
            
        end
    end
end