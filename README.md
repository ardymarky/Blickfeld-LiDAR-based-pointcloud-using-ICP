# Blickfeld
Blickfeld pointcloud data collection and processing

This github is to document the process of setting up Blickfeld Outdoor Cube 1 LiDAR system to record and visualize pointcloud data through ROS2. \
Blickfeld Cube 1 Manual: https://www.blickfeld.com/wp-content/uploads/2022/10/Blickfeld-A5-Manual_en_v.4.2.pdf \
### Main steps:
1.  Configure a Raspberry Pi 4 to run Ros2 Foxy
2.  Setup the Blickfeld Driver and record bag data
3.  Install KissICP on post-processing computer
4.  Run Rviz2 and view bag data

## Step 1: Ros2 Foxy on Raspberry Pi 4

Ros2 Foxy Documentation: https://docs.ros.org/en/foxy/Installation/Ubuntu-Install-Debians.html.

The Cube 1's provided driver requires a Ros2 Foxy Distribution. Preliminary steps to installing Ros2 include flashing an Ubuntu 20.04 image on the pi and installing any required dependencies. Should the system architecture not match, building from source will be neccessary.

## Step 2: Blickfeld Driver and Capturing Data

Driver: https://www.blickfeld.com/resources/ \
Installation Process: https://docs.blickfeld.com/cube/latest/external/ros/driver-v2/README.html

Once Ros2 Foxy has been installed on the pi, the next step is the blickfeld driver. Before building using "colcon", make sure to extract the driver and move it to the /${workspace}/src directory.

IMPORTANT: double check the Cube1 version for the BSL dependency. If neccessary, you may have to checkout an older branch before compiling BSL. BSL version history can be found at https://github.com/Blickfeld/blickfeld-scanner-lib/releases.

```console
$ cd /${BSL_directory}
$ git checkout ba53a9d (replace ba53a9d with desired branch)
```

#### Static IP Address

Documentation: https://docs.blickfeld.com/cube/latest/getting_started.

To connect to the blickfeld over a newtork switch, the ethernet adapter must be configured to a static ip address. In the pi terminal, run `ip addr` and identify the name of the ethernet cable (should be eth0). 
edit the appropriate `.yaml` file in `/etc/netplan/` and change it accordingly:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.26.xxx/24  # Static IP address
      gateway4: 192.168.26.1  # Router's IP address
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]  # DNS servers
```

Replace `xxx` with any port number that is not 0, 255, or 26. Replace the gateway4 IP address with the IP address on the back of the newtwork switch or router. Replace `eth0` with the name of the ethernet cable if different.

#### Capture Data

After configuring the driver and ethernet, run the Blickfeld Ros2 component using the command below. Be sure to publish imu topic along with pointcloud2 topic. Ctrl-C to stop recording and close the driver - bag folder should be saved to the current directory.

```console
$ ros2 component standalone blickfeld_driver blickfeld::ros_interop::BlickfeldDriverComponent -p host:=cube-XXXXXXXXX -p publish_ambient_light:=true -p publish_intensities:=false -p publish_imu:=true
```

## Step 3: Install KissICP

To post-process the bag file taken from the Blickfeld, KissICP is used because it has 

LIBGL_ALWAYS_SOFTWARE=1
