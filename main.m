% VLFeat kütüphanesini yükleme
run('C:\Users\pc\Desktop\Downloads\vlfeat-0.9.21\toolbox\vl_setup.m');

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
grayImage1 = single(rgb2gray(undistortedImage1));
grayImage2 = single(rgb2gray(undistortedImage2));

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
showMatchedFeatures(undistortedImage1, undistortedImage2, matchedPoints1, matchedPoints2, 'montage');
title('Matched Points');

% Homografi matrisini tahmin etme
[tform, inlierPoints1, inlierPoints2] = estimateGeometricTransform2D(matchedPoints1, matchedPoints2, 'projective', ...
    'MaxDistance', 3, 'Confidence', 99, 'MaxNumTrials', 10000);

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
warpedImage2 = imwarp(undistortedImage2, tform, 'OutputView', outputView);

% İki görüntüyü birleştirme
stitchedImage = max(warpedImage1, warpedImage2);

% Sonucu görselleştirme
figure;
imshow(stitchedImage);
title('Stitched Image');
