function [totalVolume,totalArea] = stlVolumeNormals(vertices,triangles)
% Given a surface triangulation, compute the volume enclosed using
% divergence theorem.
% Assumption:Triangle nodes are ordered correctly, i.e.,computed normal is outwards
% Input: p: (3xnPoints), t: (3xnTriangles), normals: (nTrianglesx3)
% Output: total volume enclosed, and total area of surface  

% Compute the vectors d13 and d12
d13= [(vertices(1,triangles(2,:))-vertices(1,triangles(3,:))); (vertices(2,triangles(2,:))-vertices(2,triangles(3,:)));  (vertices(3,triangles(2,:))-vertices(3,triangles(3,:)))];
d12= [(vertices(1,triangles(1,:))-vertices(1,triangles(2,:))); (vertices(2,triangles(1,:))-vertices(2,triangles(2,:))); (vertices(3,triangles(1,:))-vertices(3,triangles(2,:)))];
cr = cross(d13,d12,1);%cross-product (vectorized)
area = 0.5*sqrt(cr(1,:).^2+cr(2,:).^2+cr(3,:).^2);% Area of each triangle
totalArea = sum(area);
crNorm = sqrt(cr(1,:).^2+cr(2,:).^2+cr(3,:).^2);
zMean = (vertices(3,triangles(1,:))+vertices(3,triangles(2,:))+vertices(3,triangles(3,:)))/3;
nz = -cr(3,:)./crNorm;% z component of normal for each triangle

nz(find(isnan(nz)))=0;

volume = area.*zMean.*nz; % contribution of each triangle
totalVolume = abs(sum(volume));%divergence theorem