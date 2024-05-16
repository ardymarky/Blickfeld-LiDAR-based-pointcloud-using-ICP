clc;clear; close all;

downsampleGridStep = 0.1;
MergeGridStep = 0.1;
mapBuilder = helperLidarMapBuilder('DownsampleGridStep', downsampleGridStep, 'MergeGridStep', MergeGridStep)

rng(0);

lidarPointClouds = open('processedPC.mat');
closeDisplay = false;
numFrames    = length(lidarPointClouds.processedPC);
frameStepSize = 5;
tform = cell(1,numFrames);
tform{1} = rigidtform3d;

for n = 1 : frameStepSize : 80 - frameStepSize + 1

    % Get the nth point cloud
    ptCloud = lidarPointClouds.processedPC{n};
    % Use transformation from previous iteration as initial estimate for
    % current iteration of point cloud registration. (constant velocity)
    initTform = tform{n};

    % Update map using the point cloud
    tform{n+frameStepSize} = updateMap(mapBuilder, ptCloud, initTform);

    % Update map display
    updateDisplay(mapBuilder, closeDisplay);
end

figure, pcshow(mapBuilder.Map)

% % Load original point clouds and transformation matrices
% originalPointClouds = cell(1, 100); % Assuming you have 100 point clouds stored in a cell array
% icpTransforms = cell(1, 100); % Assuming you have 100 transformation matrices stored in a cell array
% 
% for i = 1:100
%     % Load original point cloud and transformation matrix for frame i
%     originalPointClouds{i} = loadPointCloudFromFrame(i); % Load the original point cloud from frame i
%     icpTransforms{i} = loadTransformFromFrame(i); % Load the transformation matrix for frame i
% end

% Apply transformations to original point clouds and combine them
% combinedPointCloud = lidarPointClouds.processedPC{1}; % Initialize combined point cloud with the first frame
% 
% for i = 1:5:50
%     % Apply transformation to the original point cloud for frame i
%     transformedPointCloud = pctransform(lidarPointClouds.processedPC{i}, tform{i});
% 
%     % Merge the transformed point cloud with the combined point cloud
%     combinedPointCloud = pcmerge(combinedPointCloud, transformedPointCloud, 0.002); % Adjust the tolerance as needed
% end
% 
% % Visualize the combined point cloud
% pcshow(combinedPointCloud);
% title('Combined Point Cloud');
% xlabel('X');
% ylabel('Y');
% zlabel('Z');