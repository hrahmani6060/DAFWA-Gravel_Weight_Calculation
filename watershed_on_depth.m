function L=watershed_on_depth_under_test(A)
hy = fspecial('sobel');
hx = hy';
Iy = imfilter(double(A), hy, 'replicate');
Ix = imfilter(double(A), hx, 'replicate');
gradmag = sqrt(Ix.^2 + Iy.^2);

se = strel('disk', 5);

Ie = imerode(A, se);
Iobr = imreconstruct(Ie, A);

Iobrd = imdilate(Iobr, se);
Iobrcbr = imreconstruct(imcomplement(Iobrd), imcomplement(Iobr));
Iobrcbr = imcomplement(Iobrcbr);

fgm = imregionalmax(Iobrcbr);

I2 = A;
I2(fgm) = 255;

se2 = strel(ones(5,5));
fgm2 = imclose(fgm, se2);
fgm3 = imerode(fgm2, se2);

fgm4 = bwareaopen(fgm3, 20);
I3 = A;
I3(fgm4) = 255;

bw = imbinarize(Iobrcbr,'adaptive');%global

D = bwdist(~bw);
DL = watershed(D);
bgm = DL == 0;

gradmag2 = imimposemin(gradmag, bgm | fgm4);

L = watershed(gradmag2);