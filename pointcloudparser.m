clc; clear; close all;

% lidarFile = "scan7/rosbag2_2024_04_24-17_27_18_0.db3";
lidarFile = "please2/rosbag2_2024_05_13-23_52_13_0.db3";
data = ros2bagreader(lidarFile)

pointcloudBag = select(data,"Topic","/bf_lidar/point_cloud_out");
imuBag = select(data,"Topic","/bf_lidar/imu_out");
pointCloudMessages = readMessages(pointcloudBag);
imuMessages = readMessages(imuBag);

baginfo = ros2('bag', 'info', lidarFile);
frames = pointcloudBag.NumMessages;

% Determine limits for the player
xlimits = [-10 15]; % meters
ylimits = [0 20];
zlimits = [-2 5];

% Create a pcplayer to visualize streaming point clouds from lidar sensor
lidarPlayer = pcplayer(xlimits, ylimits, zlimits);
processedPC = cell(1,frames);
for j = 1:frames
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
        xyz(i, :) = [x, y, z];
    end
    
    % Create a point cloud object in MATLAB
    ptCloud = pointCloud(xyz);
    processedPC{j} = ptCloud;
    
    view(lidarPlayer, ptCloud);
    pause(0.01)
end

save('processedPC.mat', "processedPC")

    