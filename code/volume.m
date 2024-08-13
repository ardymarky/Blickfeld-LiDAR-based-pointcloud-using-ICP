%% https://www.mathworks.com/help/lidar/ug/estimate-stockpile-volume-of-aerial-point-cloud.html

% Read the point cloud
clear; close all; clc;
ptCloud = pcread("outputPointCloud2.ply");
% Visualize the point cloud
neighbor_radius = 0.1;  % Radius for neighbor search
min_neighbors = 30;       % Minimum number of neighbors

% Perform radius outlier removal
[pc_filtered, outlier_indices] = pcdenoise(ptCloud, NumNeighbors=min_neighbors, Threshold=neighbor_radius);

figure
pcshow(pc_filtered)
title("Stockpile Point Cloud")
xlabel("x")
ylabel("y")
zlabel("z")

% Define a boundary around the point cloud
boundaryIndices = boundary(double(pc_filtered.Location(:,1)),double(pc_filtered.Location(:,2)));
boundaryPtCloud = pointCloud([pc_filtered.Location(boundaryIndices,:)]);
% Specify the maximum distance from an inlier point to the plane
maxDistance = 5;
% Fit a plane to the point cloud with boundary points 
[groundPlane,inlierIndices] = pcfitplane(boundaryPtCloud,maxDistance);

normalVector = groundPlane.Normal;

groundPlanePtCloud = select(boundaryPtCloud,inlierIndices);
% Visualize the ground points
figure
pcshow(groundPlanePtCloud)
title("Ground Plane of Stockpile")
xlabel("x")
ylabel("y")
zlabel("z")

% Ensure the normal vector points upwards
if normalVector(3) > 0
    % Flip the normal vector
    normalVector = -normalVector;
    % Recompute the plane coefficients with the flipped normal
    groundPlane = planeModel([normalVector, groundPlane.Parameters(4)]);
end

% Estimate the rigid transformation
referenceVector = [0 0 -1];
tform = normalRotation(groundPlane,referenceVector);

% Transform the point cloud
stockpilePtCloud = pctransform(pc_filtered,tform);

% Translation the outlier points
if abs(stockpilePtCloud.ZLimits(1)) > 0.01
    angles = [0 0 0];
    translation = [0 0 -stockpilePtCloud.ZLimits(1)-1];
    tform = rigidtform3d(angles,translation);
    stockpilePtCloud = pctransform(stockpilePtCloud,tform);
end
% Visualize the transformed stockpile point cloud
figure
pcshow(stockpilePtCloud)
title("Transformed Stockpile Point Cloud")

% Estimate the connections between the vertices
DT = delaunayTriangulation(double(stockpilePtCloud.Location(:,1)),double(stockpilePtCloud.Location(:,2)));

% Create a surface mesh around the stockpile point cloud
mesh = surfaceMesh(double(stockpilePtCloud.Location),DT.ConnectivityList);
% Visualize the surface mesh 
surfaceMeshShow(mesh)

% Estimate the volume of the stockpile mesh
dumb = 0;
for i = 1:size(mesh.Faces,1)
    tri = mesh.Faces(i,:);
    x = mesh.Vertices(tri(1),:);
    y = mesh.Vertices(tri(2),:);
    z = mesh.Vertices(tri(3),:);
    partialVol = (x(3)+y(3)+z(3))*(x(1)*y(2)-y(1)*x(2)+y(1)*z(2)-z(1)*y(2)+z(1)*x(2)-x(1)*z(2))/6;
    dumb = dumb + partialVol;
end
disp("Estimated Volume of Stockpile = " + dumb + " cubic metres")