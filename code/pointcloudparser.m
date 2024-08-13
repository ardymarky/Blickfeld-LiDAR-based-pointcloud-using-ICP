clc; clear; close all;

% lidarFile = "Aus";
lidarFile = "August_Nucor/Fourth_flight/rosbag2_2024_07_12-21_27_02_0.db3";
data = ros2bagreader(lidarFile)

pointcloudBag = select(data,"Topic","/bf_lidar/point_cloud_out");
% imuBag = select(data,"Topic","/bf_lidar/imu_out");
pointCloudMessages = readMessages(pointcloudBag);
% imuMessages = readMessages(imuBag);

baginfo = ros2('bag', 'info', lidarFile);
frames = pointcloudBag.NumMessages

% Determine limits for the player
xlimits = [-60 60]; % meters
ylimits = [-50 50];
zlimits = [-50 0];

start_frame = 1;
skip_frame = 1;
% Create a pcplayer to visualize streaming point clouds from lidar sensor
lidarPlayer = pcplayer(xlimits, ylimits, zlimits);
processedPC = cell(1, frames);
for j = start_frame:skip_frame:51
    disp(j)
    % Get the fields from the PointCloud2 message
    % fields = messages.Fields;
    point_step = pointCloudMessages{j}.point_step;
    row_step = pointCloudMessages{j}.row_step;
    data = pointCloudMessages{j}.data;
    
    % Assuming XYZ fields are present and in float32 format
    % Extract XYZ points
    num_points = length(data) / point_step;
    xyz = zeros(num_points, 3);
    
    for i = 1:num_points
        base = (i-1) * point_step + 1;
        x = typecast(data(base:base+3), 'single');
        y = typecast(data(base+4:base+7), 'single');
        z = typecast(data(base+8:base+11), 'single');
        xyz(i, :) = [x, z, -y];
        
    end
    
    % Create a point cloud object in MATLAB
    ptCloud = pointCloud(xyz);

    [pc_filtered, outlier_indices] = pcdenoise(ptCloud);
    processedPC{(j-start_frame)/skip_frame +1} = pc_filtered;
    
    view(lidarPlayer, pc_filtered);
    pause(0.01)
end


% outputFileName = 'outputPointCloud4.ply';
% pcwrite(processedPC{1}, outputFileName, 'PLYFormat', 'ascii');
save('processedPC3.mat', "processedPC")

    