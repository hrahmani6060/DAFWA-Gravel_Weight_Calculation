clear all
clc
%% High-Resolution depth image generation
foldername = [];
name = 'GS377 50g.obj';%% input obj model
xscale = 0.2; yscale = 0.2; %% depth image resolution is 0.2mm
[V,F,UV,TF,N,NF] = readOBJ([foldername name]);%% read obj point cloud model
xmin = min(V(:,1));ymin = min(V(:,2)); xmax = max(V(:,1));ymax = max(V(:,2));
[X1, Y1] = meshgrid(xmin:xscale:xmax,ymax:-yscale:ymin);%% generate meshgrid for surface
Zd = griddata(V(:,1),V(:,2),V(:,3),X1,Y1);%% fit a surface to the scatter data (V) using triangulation-based linear interpolation
max_z = max(Zd(:)); min_z = min(Zd(:)); Zd2 = (Zd-min_z)./(max_z-min_z); %% normalize depth values of output surface
imwrite(Zd2,[name '.png']);%% save high-resolution depth image
%% Depth image segmentation
d_im = imread([name '.png']);
figure; axis off;imagesc(d_im); title('Original Image');axis off
L = watershed_on_depth(d_im);%% apply Watershed transform 
figure; imagesc(L); title('Watershed label matrix (L)');
Lrgb = label2rgb(L, 'jet', 'w', 'shuffle');
figure; imshow(Lrgb); title('Colored watershed label matrix (Lrgb)');
%%
% [B,H,N,A] = bwboundaries(L); %% boundary of each segment
% largestRegionProperties =  regionprops(L,'Eccentricity','EquivDiameter','Solidity','Extent','Perimeter','Orientation','MajorAxisLength', ...
%         'Perimeter','Area','Centroid','BoundingBox','MinorAxisLength');
figure;
for i = 1:10%max(L(:))%% for each segment
    CC = zeros(size(L));
    CC(find(L == i)) = 1;
    %% add ones padding
    N=5;
    CC = ordfilt2(CC, N*N, true(N));
    %% extract 2D properties of i-th segment
    imshow(CC)
    largestRegionProperties =  regionprops(CC,'Eccentricity','EquivDiameter','Solidity','Extent','Perimeter','Orientation','MajorAxisLength', ...
        'Perimeter','Area','Centroid','BoundingBox','MinorAxisLength');
    ell_Major = largestRegionProperties.MajorAxisLength*xscale;
    ell_Minor = largestRegionProperties.MinorAxisLength*xscale;
    %% Preprocessing 
    CC_new = CC.*Zd;
    ind_new = find(CC~=0);
    CC_max = nanmax(CC_new(ind_new));
    CC_min = nanmin(CC_new(ind_new));
    fname = ['seg_no_' num2str(i) '.ply'];
    %% Volume estimation of i-th segment
    maxmin_depth = mean((CC_new(ind_new)), 'omitnan') - CC_min;
    max_depth = CC_max - CC_min;
    if (ell_Major*ell_Minor)/(maxmin_depth*maxmin_depth) > 25 %% 25 is a threshold for classifying segments to soil or gravel 
        %% the i-th segment is soil (not gravel particle)
        flag = 0;
        totalVolume = 0;
        totalArea = 0;
        max_depth = 0;
    else
        %% the i-th segment is a gravel particle
        flag = 1;
        create_mesh_segment(CC,X1,Y1,Zd,fname);%% apply delaunay triangulation to generate its mesh
        meshlab_func(fname);%% (use MeshLab software) mesh cleaning including hole filling, removing isolated pieces, etc.
        [Vs,Fs,UVs,TFs,Ns,NFs] = readOBJ('output.obj');%% read the cleaned mesh corresponding to i-th gravel segment
        [totalVolume,totalArea] = stlVolumeNormals(Vs',Fs');%% calculate volume and 3D area of i-th gravel particle
    end
    res(i,:)=[flag, ell_Minor, ell_Major, maxmin_depth, CC_max, CC_min, totalVolume, totalArea, largestRegionProperties.Solidity, largestRegionProperties.Perimeter, largestRegionProperties.Eccentricity, largestRegionProperties.Extent, largestRegionProperties.Centroid, largestRegionProperties.EquivDiameter, largestRegionProperties.Area, max_depth];%% save features corresponding to i-th segment
end
%% calculate total weight of the input sample
ind_zero = find(res(:,1)~=0);
res_new = res(ind_zero,7:8);
load('Model');%% load the learned SVR model
y_est = predict(MdlStd,res_new);%% predict the weight of each gravel particle
res(ind_zero,7) = abs(y_est);
c26=0;%% c26 is the weight of gravel particles with size >2 and <6
c619=0;%% c619 is the weight of gravel particles with size >6 and <19
c1963=0;%% c1963 is the weight of gravel particles with size >19 and <63
c63end=0;%% c63end is the weight of gravel particles with size >63
for j=1:size(res,1)
    if res(j,1)==1
        tmp = sort(res(j,2:4),'descend');
        tmp2 = sqrt((tmp(1,2)^2 + tmp(1,3)^2)/2);
        if tmp2 >= 2 && tmp2 <= 6
            c26=c26+res(j,7);
        end
        if tmp2 > 6 && tmp2 <= 19
            c619=c619+res(j,7);
        end
        if tmp2 > 19 && tmp2 <= 63
            c1963=c1963+res(j,7);
        end
        if tmp2 > 63
            c63end=c63end+res(j,7);
        end
    end
end
disp('     2=<s<6      6=<s<19      19=<s<63      63=<s')
disp([c26, c619, c1963, c63end])