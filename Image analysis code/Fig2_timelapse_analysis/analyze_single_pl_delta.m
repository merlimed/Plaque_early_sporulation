function [BW] = analyze_single_pl_delta(X)
%segmentImage Segment image using auto-generated code from imageSegmenter app
%  [BW,MASKEDIMAGE] = segmentImage(X) segments image X using auto-generated
%  code from the imageSegmenter app. The final segmentation is returned in
%  BW, and a masked image is returned in MASKEDIMAGE.

% Auto-generated by imageSegmenter app on 07-Dec-2021
%----------------------------------------------------

% Adjust data to span data range.
X = imadjust(X);
% Threshold image - manual threshold
BW = X > 160;
% Fill holes
BW = imfill(BW, 'holes');
end
