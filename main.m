% VLFeat kütüphanesini yükleme
run('C:/Users/pc/Desktop/Downloads/vlfeat-0.9.21/toolbox/vl_setup');

% Balık gözü görüntüsünü okuma ve düzeltme
fisheyeImage1 = imread('2.jpeg');
fisheyeImage2 = imread('1.jpeg');

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
    'MaxDistance', 3, 'Confidence', 99.9, 'MaxNumTrials', 10000);

% Geometrik dönüşüm matrisini inceleme
disp('Homografi matrisi:');
disp(tform.T);

% Görüntülerin boyutlarını belirleme
imageSize1 = size(fisheyeImage1);
imageSize2 = size(fisheyeImage2);
outputSize = [max(imageSize1(1), imageSize2(1)), imageSize1(2) + imageSize2(2)];

% İki görüntüyü birleştirmek için boş bir kanvas oluşturma
outputView = imref2d(outputSize);

% Birinci görüntüyü yeni kanvasa yerleştirme
warpedImage1 = imwarp(fisheyeImage1, tform, 'OutputView', outputView);

% İkinci görüntüyü de aynı kanvasa yerleştirme
tform2 = affine2d(eye(3));
warpedImage2 = imwarp(fisheyeImage2, tform2, 'OutputView', outputView);

% Maskeleri oluşturma
mask1 = ones(size(warpedImage1, 1), size(warpedImage1, 2));
mask2 = ones(size(warpedImage2, 1), size(warpedImage2, 2));

% Yumuşak geçiş için maskeleri oluşturma
mask1(:, 1:imageSize1(2)) = repmat(linspace(1, 0, imageSize1(2)), imageSize1(1), 1);
mask2(:, end-imageSize2(2)+1:end) = repmat(linspace(0, 1, imageSize2(2)), imageSize2(1), 1);

% Maskeleri normalize etme
maskSum = mask1 + mask2;
mask1 = mask1 ./ maskSum;
mask2 = mask2 ./ maskSum;

% Blending işlemi
blendedImage = uint8(double(warpedImage1) .* mask1 + double(warpedImage2) .* mask2);

% Sonucu görselleştirme
figure;
imshow(blendedImage, []);
title('Stitched Image with Improved Blending');
