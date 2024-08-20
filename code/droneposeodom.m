clc; clear; close all;

% Load Flight Logs

data = load('C:\Users\amark\OneDrive - The University of Alabama\LAGER\Nucor\August_Nucor\S900 Logs\2024-08-09 13-37-14.bin-174868.mat', 'ATT', 'POS', 'ATT_label', 'POS_label');

att = data.ATT;
att_label = data.ATT_label;
pos = data.POS;
pos_label = data.POS_label;

% Load PointCloud

lidarPointClouds = open('processedPC3.mat');
numPC = length(lidarPointClouds.processedPC);

% Global Origin
lat_0 = pos(1,3); % y
lon_0 = pos(1,4); % x
alt_0 = pos(1,5); % z

% Earth Radius in meters
earth_R = 6371000;

% Haversine formula
[a,c,dlat,dlon] = haversine(lat_0,lon_0,pos(2000,3),pos(2000,4)); % BNA to LAX
z = mod(atan2(dlat,dlon),2*pi)*180/pi;
dist = c * earth_R;
x_dist = cosd(z) * dist;
y_dist = sind(z) * dist;
z_dist = pos(2000,5) - alt_0;

%%% LLA to NED

% Yaw-pitch-roll to euler angles

points = (lidarPointClouds.processedPC{1}.Count)

world_PC = lidar_to_world(lidarPointClouds.processedPC);








rotationAngles = [0 0 0];
translation = [x_dist, y_dist, z_dist];
tform = rigidtform3d(rotationAngles,translation);

ptCloudOut1 = lidarPointClouds.processedPC{1};
ptCloudOut2 = pctransform(lidarPointClouds.processedPC{180},tform);

ptCloudOut = pcmerge(ptCloudOut1, ptCloudOut2, 0.001);

pcshow(ptCloudOut)





%% Functions

function rad = radians(degree) 
% degrees to radians
    rad = degree .* pi / 180;
end

function [a,c,dlat,dlon]=haversine(lat1,lon1,lat2,lon2)
% HAVERSINE_FORMULA.AWK - converted from AWK 
    dlat = radians(lat2-lat1);
    dlon = radians(lon2-lon1);
    lat1 = radians(lat1);
    lat2 = radians(lat2);
    a = (sin(dlat./2)).^2 + cos(lat1) .* cos(lat2) .* (sin(dlon./2)).^2;
    c = 2 .* asin(sqrt(a));
    
end

function world_PC = lidar_to_world(lidar_PC, num_)

    for i = 100:1:100

        num_points = lidar_PC{i}.Count;
        PC = lidar_PC{i}.Location;
        for j = 1:1:1
            point = PC(j,:)';
            world_point = point_transformation(point)
        end
    end

    world_PC = zeros(points,3)
end

function world_point = point_transformation(lidar_point)

    theta = 0; % pitch
    phi = 0;   % roll
    psi = 0;    % yaw
    
    Rot_D_W = [cos(theta)*cos(psi)                                 cos(theta)*sin(psi)                                 -sin(theta)
               sin(phi)*sin(theta)*cos(psi) - cos(phi)*sin(psi)    sin(phi)*sin(theta)*sin(psi) + cos(phi)*cos(psi)    sin(phi)*cos(theta)
               cos(phi)*sin(theta)*cos(psi) + sin(phi)*sin(psi)    cos(phi)*sin(theta)*sin(psi) - sin(phi)*cos(psi)    cos(phi)*cos(theta)];
    
    Rot_L_D = [1 0 0; 
               0 -1 0;
               0 0 1];
    
    P_test = lidar_point % x, y, z
    % P_test = [0,0,10]'
    
    P_w = inv(Rot_L_D * Rot_D_W) * P_test

end