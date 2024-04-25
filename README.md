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

```console
$ whoami
```
