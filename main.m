% VLFeat kütüphanesini yükleme
run('C:/Users/pc/Desktop/Downloads/vlfeat-0.9.21/toolbox/vl_setup');

% Balık gözü görüntüsünü okuma
fisheyeImage1 = imread('1.jpeg');
fisheyeImage2 = imread('2.jpeg');

% Grayscale'e dönüştürme
grayImage1 = single(rgb2gray(fisheyeImage1));
grayImage2 = single(rgb2gray(fisheyeImage2));

% SIFT özelliklerini tespit etme
[frames1, descriptors1] = vl_sift(grayImage1);
[frames2, descriptors2] = vl_sift(grayImage2);

% Özellik eşleştirme
[matches, scores] = vl_ubcmatch(descriptors1, descriptors2);

% Eşleşen noktaları elde etme
matchedPoints1 = frames1(1:2, matches(1,:))';
matchedPoints2 = frames2(1:2, matches(2,:))';

% Yeterli sayıda eşleşen nokta olup olmadığını kontrol etme
if size(matchedPoints1, 1) < 4 || size(matchedPoints2, 1) < 4
    error('Yeterli sayıda eşleşen nokta bulunamadı.');
end

% Eşleşen noktaları görselleştirme
figure;
showMatchedFeatures(fisheyeImage1, fisheyeImage2, matchedPoints1, matchedPoints2, 'montage');
title('Matched Points');

% Homografi matrisini tahmin etme
[tform, inlierPoints1, inlierPoints2] = estimateGeometricTransform2D(matchedPoints1, matchedPoints2, 'projective', ...
    'MaxDistance', 10, 'Confidence', 99, 'MaxNumTrials', 20000);  % Daha fazla güven ve mesafe

% Geometrik dönüşüm matrisini inceleme
disp('Homografi matrisi:');
disp(tform.T);

% Görüntülerin boyutlarını belirleme
imageSize = size(fisheyeImage1);

% İki görüntüyü birleştirmek için boş bir kanvas oluşturma
outputView = imref2d([imageSize(1) imageSize(2)*2]);

% Birinci görüntüyü yeni kanvasa yerleştirme
warpedImage1 = imwarp(fisheyeImage1, tform, 'OutputView', outputView);

% İkinci görüntüyü yeni boyutlarına göre yeniden boyutlandırma
warpedImage2 = imwarp(fisheyeImage2, affine2d(eye(3)), 'OutputView', outputView);

% Maskeleri oluşturma
mask1 = ones(size(warpedImage1, 1), size(warpedImage1, 2));
mask2 = ones(size(warpedImage2, 1), size(warpedImage2, 2));

% Feathering için maske oluşturma
featherAmount = min(100, size(mask2, 2));  % Feathering miktarını artırma

% Feathering ile mask1 oluşturma
mask1(:, 1:imageSize(2)) = repmat(linspace(1, 0, imageSize(2)), imageSize(1), 1);
mask1(:, imageSize(2)-featherAmount+1:imageSize(2)) = repmat(linspace(1, 0, featherAmount), imageSize(1), 1);

% Feathering ile mask2 oluşturma
mask2(:, end-imageSize(2)+1:end) = repmat(linspace(0, 1, imageSize(2)), size(mask2, 1), 1);
mask2(:, end-featherAmount+1:end) = repmat(linspace(0, 1, featherAmount), size(mask2, 1), 1);

% Maskeleri normalize etme
maskSum = mask1 + mask2;
mask1 = mask1 ./ maskSum;
mask2 = mask2 ./ maskSum;

% Maskeleri uygulayarak blend etme
blendedImage = uint8(double(warpedImage1) .* mask1 + double(warpedImage2) .* mask2);

% Sonucu görselleştirme
figure;
imshow(blendedImage);
title('Stitched Image with Enhanced Feathered Blending');
