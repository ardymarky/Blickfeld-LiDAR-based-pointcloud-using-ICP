clc; clear; close all;

lidarFile = "TestFlight3Overhead/rosbag.db3";
% lidarFile = "please2/rosbag2_2024_05_13-23_52_13_0.db3";
data = ros2bagreader(lidarFile)

% pointcloudBag = select(data,"Topic","/bf_lidar/point_cloud_out");
imuBag = select(data,"Topic","/bf_lidar/imu_out");
% pointCloudMessages = readMessages(pointcloudBag);
imuMessages = readMessages(imuBag);
frames = imuBag.NumMessages;
vel = cell(3, frames);
accel = cell(3, frames);

for j = 1:frames
    vel{1,j} = imuMessages{j}.angular_velocity.x;
    vel{2,j} = imuMessages{j}.angular_velocity.y;
    vel{3,j} = imuMessages{j}.angular_velocity.z;
    accel{1,j} = imuMessages{j}.linear_acceleration.x;
    accel{2,j} = imuMessages{j}.linear_acceleration.y;
    accel{3,j} = imuMessages{j}.linear_acceleration.z;
end

modelname = openExample('nav/ComputeOrientationFromRecordedIMUDataBlockExample');
open_system(modelname)
set_param(modelname,"StartTime","0.005","StopTime","8")
sim(modelname);