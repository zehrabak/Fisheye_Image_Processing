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
    'MaxDistance', 3, 'Confidence', 99.9, 'MaxNumTrials', 10000);

% Geometrik dönüşüm matrisini inceleme
disp('Homografi matrisi:');
disp(tform.T);

% Görüntülerin boyutlarını belirleme
imageSize = size(fisheyeImage1);

% İki görüntüyü birleştirmek için boş bir kanvas oluşturma
outputView = imref2d([imageSize(1) imageSize(2)*2]);

% Birinci görüntüyü yeni kanvasa yerleştirme
warpedImage1 = imwarp(fisheyeImage1, tform, 'OutputView', outputView);

% İkinci görüntüyü de aynı kanvasa yerleştirme
warpedImage2 = imwarp(fisheyeImage2, projective2d(eye(3)), 'OutputView', outputView);

% Blend maskesi oluşturma
mask1 = zeros(size(warpedImage1, 1), size(warpedImage1, 2));
mask1(:, 1:imageSize(2)) = 1;
mask2 = 1 - mask1;

% Gaussian blur uygulayarak maskeleri yumuşatma
sigma = 50;
mask1 = imgaussfilt(mask1, sigma);
mask2 = imgaussfilt(mask2, sigma);

% Maskeleri normalize etme
maskSum = mask1 + mask2;
mask1 = mask1 ./ maskSum;
mask2 = mask2 ./ maskSum;

% Blend işlemi
blendedImage = uint8(mask1 .* double(warpedImage1) + mask2 .* double(warpedImage2));

% Sonucu görselleştirme
figure;
imshow(blendedImage, []);
title('Stitched Image with Blending');
