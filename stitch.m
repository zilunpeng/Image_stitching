function combined = stitch(pairs,matchedPts2,matchedPts3,I2,I3,combined)
num_pairs = size(pairs,1);
tot_iter = 200;
threshold = 2;
consensus_size = -Inf;
consensus_x = 0;
consensus_y = 0;
consensus_x_tilda = 0;
consensus_y_tilda = 0;

for i=1:tot_iter
    %Find H
    A = zeros(2*4,9);
    four_pts = randsample(num_pairs,4);
    x = matchedPts3(four_pts,1);
    y = matchedPts3(four_pts,2);
    x_tilda = matchedPts2(four_pts,1);
    y_tilda = matchedPts2(four_pts,2);
    A([1,3,5,7],1:3) = [x y ones(4,1)];
    A([1,3,5,7],7:9) = [-x_tilda.*x -x_tilda.*y -x_tilda];
    A([2,4,6,8],4:6) = [x y ones(4,1)];
    A([2,4,6,8],7:9) = [-y_tilda.*x -y_tilda.*y -y_tilda];
    [H,D] = eig(A'*A);
    H = H(:,1);
    H = reshape(H,3,3);
    H = H';
    
    %Find consensus set
    other_pts = setdiff(1:num_pairs, four_pts);
    x = matchedPts3(other_pts,1);
    y = matchedPts3(other_pts,2);
    x_tilda = matchedPts2(other_pts,1);
    y_tilda = matchedPts2(other_pts,2);
    matched_pts = H*[x';y';ones(1,length(other_pts))];
    matched_pts(1:2,:) = matched_pts(1:2,:)./matched_pts(3,:);
    diff = matched_pts(1:2,:) - [x_tilda'; y_tilda'];
    diff = sqrt(sum(diff.*diff));
    
    ind = find(diff<threshold);
    %Update if found a larger consensus set
    if length(ind) > consensus_size
        consensus_x = x(ind);
        consensus_y = y(ind);
        consensus_x_tilda = x_tilda(ind);
        consensus_y_tilda = y_tilda(ind);
        consensus_size = length(ind);
    end
end

%Use consensus set to find H
A = zeros(consensus_size*2,9);
A(1:2:consensus_size*2-1, 1:3) = [consensus_x consensus_y ones(consensus_size,1)];
A(1:2:consensus_size*2-1, 7:9) = [-consensus_x_tilda.*consensus_x -consensus_x_tilda.*consensus_y -consensus_x_tilda];
A(2:2:consensus_size*2, 4:6) = [consensus_x consensus_y ones(consensus_size,1)];
A(2:2:consensus_size*2, 7:9) = [-consensus_y_tilda.*consensus_x -consensus_y_tilda.*consensus_y -consensus_y_tilda];
[H,D] = eig(A'*A);
H = H(:,1);
H = reshape(H,3,3);
H = H';

%apply homography
[img_w, img_h] = size(I3);
[x_pix, y_pix] = meshgrid(1:img_h, 1:img_w);
Img = [x_pix(:)';y_pix(:)';ones(1,img_w*img_h)];
Img_T = H*Img;
Img_T(1:2,:) = Img_T(1:2,:)./Img_T(3,:);
Img_T = Img_T(1:2,:);

%find cut off position
[valid_px_x_ind, valid_px_y_ind] = find(Img_T(1,:)>=double(1) & Img_T(1,:)<=double(img_h) & Img_T(2,:)>=double(1) & Img_T(2,:)<=double(img_w));
cutoff_y = max(Img(2,valid_px_y_ind));

%stitch
cropped_size = img_w - cutoff_y;
[combined_h, combined_w] = size(combined);
Img = zeros(combined_h+cropped_size, combined_w);
Img(1:combined_h,1:combined_w) = combined;
Img(combined_h+1:end,1:combined_w) = I3(cutoff_y+1:end,1:combined_w);
combined = Img;

clearvars -except combined
end

