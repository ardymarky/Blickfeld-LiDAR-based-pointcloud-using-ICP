clc;clear; close all;

downsampleGridStep = 0.05;
MergeGridStep = 0.05;
RegistrationInlierRatio = 0.9;
mapBuilder = helperLidarMapBuilder('DownsampleGridStep', downsampleGridStep, 'MergeGridStep', MergeGridStep, 'RegistrationInlierRatio', RegistrationInlierRatio, 'Verbose', true);

rng(0);

% lidarPointClouds = open('processedPC3.mat');
lidarPointClouds = open('August_Nucor/Fourth_flight.mat')
closeDisplay = false;
numFrames    = length(lidarPointClouds.processedPC);
frameStepSize = 1;
tform = cell(1,numFrames);
tform{1} = rigidtform3d;

for n = 1 : frameStepSize : 275
    disp(n)
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

outputFileName = 'outputPointCloud2.ply';
pcwrite(mapBuilder.Map, outputFileName, 'PLYFormat', 'ascii');
