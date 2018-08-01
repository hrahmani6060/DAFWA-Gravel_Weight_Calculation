function meshlab_func(fname)
cd 'C:\Program Files\VCG\MeshLab'%% path to meshlab folder where "meshlabserver.exe" exists
!meshlabserver -i C:\Code\input.ply -o C:\Code\output.obj -m vc vn fn -s C:\Code\Seg_filter001.mlx
cd 'C:\Code'%% return to current path