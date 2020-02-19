clear all
close all

num_imgs = 5;
for i=1:num_imgs-1
    
    cd Dataset1
    I2 = imread(strcat(int2str(i),'.jpg'));
    I3 = imread(strcat(int2str(i+1),'.jpg'));
    cd ..
        
    I2 = single(rgb2gray(I2));
    I3 = single(rgb2gray(I3));
    
    %compile vlfeat
    run('vlfeat-0.9.20/toolbox/vl_setup')
    
%     %apply sift
    [f2,d2] = vl_sift(I2);
    [f3,d3] = vl_sift(I3);
    
%     %extract features
    f3 = [f3 repmat(f3(:,end),1,size(d2,2)-size(d3,2))];
    d3 = [d3 repmat(d3(:,end),1,size(d2,2)-size(d3,2))]; %make feature vectors to have same length
    d2 = d2';
    d3 = d3';
    
    feature2 = binaryFeatures(d2);
    feature3 = binaryFeatures(d3);
    
    %matching points
    pairs = matchFeatures(feature2,feature3,'Method','Approximate','MatchThreshold',50,'MaxRatio',0.8);
    
    %show matched pts
    matchedPts2 = f2(1:2,pairs(:,1));
    matchedPts3 = f3(1:2,pairs(:,2));
    matchedPts2 = matchedPts2';
    matchedPts3 = matchedPts3';
    figure; showMatchedFeatures(I2,I3,matchedPts2,matchedPts3);
    legend('matched points 2','matched points 3');
    
    if i==1
        combined = I2;
        combined = stitch(pairs,matchedPts2,matchedPts3,I2,I3,combined);
    else
        combined = stitch(pairs,matchedPts2,matchedPts3,I2,I3,combined);
    end
end
figure(6)
imshow(uint8(combined));

