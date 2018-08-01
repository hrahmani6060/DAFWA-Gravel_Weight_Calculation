function create_mesh_segment(CC,X1,Y1,Zd,fname)
ind_new = find(CC~=0);
x_p = X1(ind_new);
y_p = Y1(ind_new);
z_p = Zd(ind_new);
data=[x_p,y_p,z_p];
find(isnan(data(:,3)));
data(find(isnan(data(:,3))),:)=[];

tri = delaunay(data(:,1), data(:,2));
%trimesh(tri, data(:,1), data(:,2), data(:,3));
mesh.vertices=data;
mesh.triangles=tri;

% mesh = pointCloud2rawMesh(data);
fname='input.ply';
makePly(mesh, fname);

