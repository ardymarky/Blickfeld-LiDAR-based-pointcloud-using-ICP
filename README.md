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

Ros2 Foxy Documentation: https://docs.ros.org/en/foxy/Installation/Ubuntu-Install-Debians.html.

The Cube 1's provided driver requires a Ros2 Foxy Distribution. Preliminary steps to installing Ros2 include flashing an Ubuntu 20.04 image on the pi and installing any required dependencies. Should the system architecture not match, building from source will be neccessary.

## Step 2: Blickfeld Driver

Driver: https://www.blickfeld.com/resources/ \
Installation Process: https://docs.blickfeld.com/cube/latest/external/ros/driver-v2/README.html

Once Ros2 Foxy has been installed on the pi, the next step is the blickfeld driver. Before building using "colcon", make sure to extract the driver and move it to the /${workspace}/src directory.

IMPORTANT: double check the Cube1 version for the BSL dependency. If neccessary, you may have to checkout an older branch before compiling BSL. BSL version history can be found at https://github.com/Blickfeld/blickfeld-scanner-lib/releases.

```console
$ cd /${BSL_directory}
$ git checkout ba53a9d (replace ba53a9d with desired branch)
```

After configuring the driver, run the Blickfeld Ros2 component using the command below. Be sure to publish imu topic along with pointcloud2 topic.

```console
ros2 component standalone blickfeld_driver blickfeld::ros_interop::BlickfeldDriverComponent -p host:=cube-XXXXXXXXX -p publish_ambient_light:=true -p publish_intensities:=false -p publish_imu:=true
```
```console
$ whoami
```
