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

% İkinci görüntüyü yeni boyutlarına göre yeniden boyutlandırma
warpedImage2 = imwarp(fisheyeImage2, affine2d(eye(3)), 'OutputView', outputView);

% Boyutları eşitleme
warpedImage2 = imresize(warpedImage2, size(warpedImage1(:,:,1)));

% Laplacian Pyramid Blending Fonksiyonları
function [lp, gp] = laplacianPyramid(img, level)
    gp = cell(level, 1);
    lp = cell(level, 1);
    current = img;
    for i = 1:level
        gp{i} = current;
        down = impyramid(current, 'reduce');
        up = imresize(impyramid(down, 'expand'), size(current(:,:,1)));
        lp{i} = current - up;
        current = down;
    end
    gp{level} = current;
    lp{level} = current;
end

function blended = blendPyramids(lp1, lp2, mask, level)
    blended = cell(level, 1);
    for i = 1:level
        blended{i} = lp1{i} .* mask + lp2{i} .* (1 - mask);
    end
end

function result = reconstructPyramid(lp, level)
    current = lp{level};
    for i = level-1:-1:1
        up = imresize(impyramid(current, 'expand'), size(lp{i}(:,:,1)));
        current = lp{i} + up;
    end
    result = current;
end

% Görüntüler için Laplacian Pyramid Oluşturma
levels = 4; % Piramit seviyesi
[lp1, gp1] = laplacianPyramid(im2double(warpedImage1), levels);
[lp2, gp2] = laplacianPyramid(im2double(warpedImage2), levels);

% Maskeleri Oluşturma
mask = ones(size(warpedImage1, 1), size(warpedImage1, 2));
blendWidth = round(imageSize(2) / 6);
mask(:, end-blendWidth+1:end) = repmat(linspace(1, 0, blendWidth), size(mask, 1), 1);
mask(:, 1:blendWidth) = repmat(linspace(0, 1, blendWidth), size(mask, 1), 1);

% Maskeyi Gaussian Blur ile Yumuşatma
mask = imgaussfilt(mask, 10);

% Pyramid Blending
blendedPyramid = blendPyramids(lp1, lp2, mask, levels);

% Sonucu Yeniden Yapılandırma
blendedImage = reconstructPyramid(blendedPyramid, levels);

% Sonucu Görselleştirme
figure;
imshow(blendedImage, []);
title('Stitched Image with Laplacian Pyramid Blending');
