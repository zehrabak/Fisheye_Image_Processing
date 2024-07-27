% Kalibrasyon verilerini yükleme
load('calibrationSession1.mat', 'calibrationSession');

% 'calibrationSession' içindeki 'CameraParameters' alanını kullanarak 'cameraParams' elde etme
cameraParams = calibrationSession.CameraParameters;

% Intrinsics değerini elde etme
intrinsics = cameraParams.Intrinsics;

% Balık gözü görüntüsünü okuma ve düzeltme
fisheyeImage1 = imread('Im_L_1.png');
fisheyeImage2 = imread('Im_R_1.png');

undistortedImage1 = undistortFisheyeImage(fisheyeImage1, intrinsics, 'OutputView', 'full');
undistortedImage2 = undistortFisheyeImage(fisheyeImage2, intrinsics, 'OutputView', 'full');

% Sonucu gösterme
figure;
imshowpair(fisheyeImage1, undistortedImage1, 'montage');
title('Original (left) vs. Undistorted (right) Image 1');

figure;
imshowpair(fisheyeImage2, undistortedImage2, 'montage');
title('Original (left) vs. Undistorted (right) Image 2');
% Grayscale'e dönüştürme
grayImage1 = rgb2gray(undistortedImage1);
grayImage2 = rgb2gray(undistortedImage2);

% SIFT algoritması ile özellikleri algılama
points1 = detectSURFFeatures(grayImage1);
points2 = detectSURFFeatures(grayImage2);

% Özellik tanımlayıcılarını çıkarma
[features1, validPoints1] = extractFeatures(grayImage1, points1);
[features2, validPoints2] = extractFeatures(grayImage2, points2);

% Özellik eşleştirme
indexPairs = matchFeatures(features1, features2, 'MaxRatio', 0.9, 'MatchThreshold', 100);

% Eşleşen noktaları elde etme
matchedPoints1 = validPoints1(indexPairs(:, 1));
matchedPoints2 = validPoints2(indexPairs(:, 2));

% Eşleşen noktaları görselleştirme
figure;
showMatchedFeatures(undistortedImage1, undistortedImage2, matchedPoints1, matchedPoints2);
title('Matched Points');

% Homografi matrisini tahmin etme
   [tform, inlierPoints1, inlierPoints2] = estimateGeometricTransform(matchedPoints1, matchedPoints2, 'projective', ...
        'MaxDistance', 2, 'Confidence', 99.9, 'MaxNumTrials', 10000);

% Geometrik dönüşüm matrisini inceleme
disp('Homografi matrisi:');
disp(tform.T);

% Görüntülerin boyutlarını belirleme
imageSize = size(undistortedImage1);

% İki görüntüyü birleştirmek için boş bir kanvas oluşturma
outputView = imref2d(imageSize);

% Birinci görüntüyü yeni kanvasa yerleştirme
warpedImage1 = imwarp(undistortedImage1, tform, 'OutputView', outputView);

% İkinci görüntüyü de aynı kanvasa yerleştirme
warpedImage2 = undistortedImage2;

% İki görüntüyü birleştirme
stitchedImage = max(warpedImage1, warpedImage2);

% Sonucu görselleştirme
figure;
imshow(stitchedImage);
title('Stitched Image');