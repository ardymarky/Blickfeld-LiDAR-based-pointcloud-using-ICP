# Blickfeld
Blickfeld pointcloud data collection and processing

This github is to document the process of setting up Blickfeld Outdoor Cube 1 LiDAR system to record and visualize pointcloud data through ROS2.
### Main steps:
1.  Configure a Raspberry Pi 4 to run Ros2 Foxy
2.  Setup the Blickfeld Driver on the pi
3.  Record Ros2 Bag Data
4.  Install KissICP on post-processing computer
5.  Run Rviz2 and view bag data

## Step 1: Ros2 Foxy on Raspberry Pi 4

The Cube 1's provided driver requires a Ros2 Foxy Distribution. This can be accomplished using Ros2's documentation: https://docs.ros.org/en/foxy/Installation/Ubuntu-Install-Debians.html.
Preliminary steps to installing Ros2 include flashing an Ubuntu 20.04 image on the pi and installing any required dependencies. Should the system architecture not match, building from source will be neccessary.

## Step 2: Blickfeld Driver

Once Ros2 Foxy has been installed on the pi, the next step is the blickfeld driver: https://docs.blickfeld.com/cube/latest/external/ros/driver-v2/README.html
Make sure to install all dependencies (from source if neccessary) and download the drive from https://www.blickfeld.com/resources/.
Before building using "colcon", make sure to extract the driver and move it to the /${workspace}/src directory.

Running the Blickfeld Ros2 component gave the best results.
```console
ros2 component standalone blickfeld_driver blickfeld::ros_interop::BlickfeldDriverComponent -p host:=cube-XXXXXXXXX -p publish_ambient_light:=true -p publish_intensities:=false
```
```console
$ whoami
```
