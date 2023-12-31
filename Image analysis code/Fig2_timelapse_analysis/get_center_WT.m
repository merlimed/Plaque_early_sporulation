% This code takes the last frame from cropped plate for S( same as WT)
% strain and gets the centers of plaques 
clear
clc
%%
A = imread("cropped/WT_DSM_SPO1_179.jpg");
imshow(A)
%% Use filters to emphasize contrast 
se = strel("disk",25); 
Aprime = imopen(A, se); %Average over discs of radius 25
A_adj = imadjust(A-Aprime); % subtract average
A_adj = imgaussfilt(A_adj,1.5); % reduce noise
A_mask = A_adj > 170; % use general threshold to binarize 

SE=strel('disk',1);
%apply the erosion operation.
A_mask = imerode(A_mask,SE); %logical matrix
%View mask on top of adjusted image, 'montage' puts them next to each other
figure()
imshowpair(A_adj, A_mask)
%% get connected components and properties
A_bw = bwlabel(A_mask); %matrix of double
A_CC = regionprops(A_mask, 'all');
A_CC_color = label2rgb (A_bw, 'hsv', 'k', 'shuffle'); % pseudo random color labels
n_CC = size(A_CC, 1);

%% select CC based on area and maybe circularity
CC_circ = [A_CC.Circularity];
CC_areas = [A_CC.Area];
% circularity larger than a threshold 
allowableCircularityIndexes = CC_circ > 0.5; 
%are between two numbers 
allowableAreaIndexes = (CC_areas >=25) & (CC_areas < .5*10^3); 
keeperIndexes = find(allowableAreaIndexes & allowableCircularityIndexes);
A_mask_new = ismember(A_bw, keeperIndexes); %logical matrix

% Re-label with only the CC we selected
A_bw_new = bwlabel(A_mask_new, 8);     % Label each CC 
% Plot before and after selection
A_CC_new_color = label2rgb (A_bw_new, 'hsv', 'k', 'shuffle'); % pseudo random color labels

%figure()
%imshowpair(A_adj, A_mask_new)
figure()
imshowpair(A_mask, A_mask_new, 'montage')
%% Do watershed algorithm, oversegmentation problem
% code adapted from mathworks
D = bwdist(~A_mask_new);
D = -D;
D = imgaussfilt(D,3); % reduce noise

L = watershed(D);
L(~A_mask_new) = 0;
rgb = label2rgb(L,'jet',[.5 .5 .5]);
figure()
imshow(A)
figure()
imshow(rgb)
title('Watershed Transform')
%% Plot connected components with numbers
A_mask_new = L > 0;
CC_M_new = regionprops(A_mask_new, 'all');
n_CC_new = size(CC_M_new, 1);

figure()
imshow(A_CC_new_color)
hold on 
textFontSize = 14;	% Used to control size of "blob number" labels put atop the image.
labelShiftX = -7;	% Used to align the labels in the centers of the coins.
blob_areas = zeros(1, n_CC_new);

for k = 1 : n_CC_new           % Loop through all blobs.
	thisBlobsPixels = CC_M_new(k).PixelIdxList;  % Get list of pixels in current blob.
	meanGL = mean(Aprime(thisBlobsPixels)); % Find mean intensity (in original image!)
	
	blobArea = CC_M_new(k).Area;		% Get area.
	blobPerimeter = CC_M_new(k).Perimeter;		% Get perimeter.
	blobCentroid = CC_M_new(k).Centroid;		% Get centroid one at a time
	blob_areas(k) = blobArea;					% Compute ECD - Equivalent Circular Diameter.
	% Put the "blob number" labels on the "boundaries" grayscale image.
	text(blobCentroid(1) + labelShiftX, blobCentroid(2), num2str(k), 'FontSize', textFontSize, 'FontWeight', 'Bold', 'Color', [1 1 1]);
end
%% Delete some plaques by hand :(
%delete misidentification in decreasing order
A_bw_new = bwlabel(A_mask_new, 8);
allowableIndexes = 1: size(CC_M_new, 1);
allowableIndexes(102) = [];
allowableIndexes(63) = [];
allowableIndexes(1) = [];


A_mask_fin = ismember(A_bw_new, allowableIndexes);
A_bw_fin = bwlabel(A_mask_fin, 8);  
% Plot before and after selection with pseudo random color labels
A_CC_color_fin = label2rgb (A_bw_fin, 'hsv', 'k', 'shuffle'); 
A_CC_fin = regionprops(A_mask_fin, 'all');

figure()
imshowpair(A_CC_new_color, A_CC_color_fin, 'montage')
%% IMPORTANT visual check
figure('Position', [100 200 1200 400])
tiledlayout(1,3, 'Padding', 'none', 'TileSpacing', 'compact'); 
nexttile
imshow(A)
title('Original', 'FontSize', 16)
nexttile
imshowpair(A_adj, A_mask_fin)
title('Processed', 'FontSize', 16)
nexttile
imshow(A_adj)
hold on
centroids = cat(1,A_CC_fin.Centroid);
axes_1 = cat(1, A_CC_fin.MajorAxisLength);
axes_2 = cat(1, A_CC_fin.MinorAxisLength);
plot(centroids(:,1), centroids(:,2), 'rx','MarkerSize', 5, ...
    'LineWidth', 1)
title('Find and overlay centers', 'FontSize', 16)

%%
stats = [axes_1, axes_2];
stats = [stats, centroids];
%%
writematrix(stats, 'Data/WT_nov19_centers.csv')
