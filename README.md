# Blickfeld pointcloud data collection and processing

This github is to document the process of setting up a Blickfeld Outdoor Cube 1 LiDAR system to record and visualize pointcloud data through ROS2. This in an ongoing process by LAGER and Nucor, and led by Arden Markin.

## Configuration steps:
1.  Configure a Raspberry Pi 4 to run Ros2 Foxy
2.  Install BSL and Blickfeld Driver
3.  System Setup
    * Static IP address
    * GPS
    * LED indicators
    * HDMI on boot
    * Execute on system boot
    * Enable SSH
4.  Capture LiDAR data
5.  Post-process PointCloud in Matlab

[Blickfeld Cube 1 Manual](https://www.blickfeld.com/wp-content/uploads/2022/10/Blickfeld-A5-Manual_en_v.4.2.pdf)

## Step 1: Ros2 Foxy on Raspberry Pi 4

[Ros2 Foxy Docs](https://docs.ros.org/en/foxy/Installation/Ubuntu-Install-Debians.html)

The Cube 1's provided driver requires a Ros2 Foxy Distribution. Preliminary steps to installing Ros2 include flashing an Ubuntu 20.04 image on the pi and installing any required dependencies. Should the system architecture not match, building from source will be neccessary.

## Step 2: BSL and Blickfeld Driver Setup

[Blickfeld Driver](https://www.blickfeld.com/resources/) \
[Installation Process](https://docs.blickfeld.com/cube/latest/external/ros/driver-v2/README.html)

When installing BSL, build it from source with installed dependencies. Install protoc buffers and cmake via available packages.

Once Ros2 Foxy has been installed on the pi, the next step is the blickfeld driver. Before building using "colcon", make sure to extract the driver and move it to the /${workspace}/src directory.

IMPORTANT: double check the Cube1 for its BSL version dependency. If neccessary, you may have to checkout an older branch before compiling BSL. BSL version history can be found [here](https://github.com/Blickfeld/blickfeld-scanner-lib/releases). Replace ba53a9d with the desired branch/release.

```console
cd /${BSL_directory}
git checkout ba53a9d
```

## Step 3: System Setup

### Static IP Address

[Documentation](https://docs.blickfeld.com/cube/latest/getting_started)

To connect to the blickfeld over a network switch, the ethernet adapter must be configured to a static ip address. In the Raspberry Pi terminal, run `ip addr` and identify the name of the ethernet cable (should be eth0). 
Edit the appropriate `.yaml` file in `/etc/netplan/` and change it accordingly:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 192.168.26.xxx/24  # Static IP address
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]  # DNS servers
      dhcp4: true
      optional: true
```

Replace `xxx` with any port number that is not 0, 255, or 26. Replace `eth0` with the name of the ethernet cable if different. Alternatively, replace the file contents with the contents in `netplan.yaml`.
After making changes to the yaml file, run `sudo netplan apply` to apply the changes.

### GPS over UART

To get GPS working over UART, U-boot must be configured manually so that serial console isn't corrupted by the new serial uart on boot. Follow the steps [avaiable here.](https://raspberrypi.stackexchange.com/questions/116074/how-can-i-disable-the-serial-console-on-distributions-that-use-u-boot/117950#117950)

Breakout the UART's TX and ground cables, and connect them to GPIO pins 6 and 10 respectively. Ensure your GPS receiver is sending UBX-NAV-TIMEGPS messages. Should the RPI4 successfully connect to the receiver, the system time should be correctly set and the led indicator light will turn green. Each subsequent recorded BAG file with then be time stamped in the following format: `Hour:Minute Month/Day/Year Scan`

### LED indicators

To assist the operator in tracking the status of the system without the need to remote-in or an external monitor, led indicator lights were used. Connect the red led to pin 22 (GPIO 25) and the green led to pin 18 (GPIO 24). Connect their ground to pin 20.

| Color    | Behavior | Status |
| -------- | ------- | ------- |
| Red  | Slow blinking    | Searching for LiDAR |
| Red  | Rapid blinking    | Searching for GPS |
| Red  | Solid  | System is ready/standby |
| Green  | Solid   | Recording/Saving |

### HDMI on boot

If no HDMI is plugged into the Raspberry Pi 4, relay.py will not automatically run for some reason. To work around this issue, configure `boot/firmware/config.txt` to always output HDMI even if no output source is detected.

```console
# Force HDMI even if no monitor is detected
hdmi_force_hotplug=1

# Uncomment if you have trouble with the Pi detecting your display or outputting
# hdmi_safe=1
# hdmi_ignore_edid=0xa5000080
```
### Execute on system boot

Because the python script uses a subprocess/new terminal to execute ROS commands, crontab can't properly execute the commands. Instead, simply add the command `/usr/bin/python3 /path/to/relay_boot.py/file in <strong>Startup Applications</strong>.

### SSH through LAN

[SSH/LAN Docs](https://serverastra.com/docs/Tutorials/Setting-Up-and-Securing-SSH-on-Ubuntu-22.04%3A-A-Comprehensive-Guide) \
[FileZilla](https://filezilla-project.org/)

To setup SSH through the network switch over LAN, follow the steps in the link above. To transfer files, connect a laptop to the network switch and run FileZilla or any other file transfering application.
Should it not connect through LAN, check the laptop's ethernet cable connection, manually setting the subnet to `192.168.26.X` and the mask to `255.255.255.0` if necessary.

Also you may need to uncomment: `PasswordAuthentication yes` in `/etc/ssh/sshd_config` to login.

## Step 4: Capture Data

After configuring the driver and ethernet, run the Blickfeld Ros2 component using the command below. This will begin to send Ros PointCloud2 messages. To also record an intensity image, append `-p publish_intensities:=true -p publish_intensity_image:=true` To also record imu data, append `-p publish_imu:=true -p publish_imu_static_tf_at_start:=true`

```console
source ${colcon dir}/install/setup.bash
ros2 component standalone blickfeld_driver blickfeld::ros_interop::BlickfeldDriverComponent -p host:=192.168.26.26 
```

In a seperate terminal, setup a ros2 listener to record the PointCloud2 data to a bagfile. After the scan has been completed, press Ctrl-C to stop recording and close the driver - bag folder should be saved to the current directory.

```console
source ${colcon dir}/install/setup.bash
ros2 bag record /bf_lidar/point_cloud_out
```

## Step 5: Matlab ICP

To post-process the bag file taken from the Blickfeld, the Matlab ICP Map Builder is used.

[Matlab Guide](https://www.mathworks.com/help/driving/ug/build-a-map-from-lidar-data.html) \
[Matlab Install](https://www.mathworks.com/help/install/install-products.html)

Open Matlab and run `pointcloudparser.m`, modifying the file as required. This will parse the Ros2 PointCloud into a format Matlab can understand. Once the script finishes running, run `icpsolver.m`. This will output a combined PointCloud as a `.ply` file.

Should Matlab throw the error `'helperLidarMapBuilder' is used in the following examples...`, download `helperLidarMapBuilder.m` and add it to the current directory.

## Extra Steps / Miscellaneous Details

### Relay Switch

Running `relay.py` on boot gives the LiDAR system a relay switch that either starts or stops the recording process. When the relay is on, data is being saved to a ros2 bagfile.

### LAGER specific Deployment Procedure

1.  Attach Lidar to S900 via mount. M4 and M2 drivers are needed to secure payload.
2.  Plug relay pin into Aux Out Pin 6 on the Cube
3.  Connect three way to the drone's power cable and power on
4.  Wait at LEAST 100 seconds for system to completely boot
5.  From transmitter, turn relay on (switch E) and wait at LEAST 40 seconds.
6.  Verify laser is on via flashing lights, filezilla connection, or visually seeing the laser pulses. \
      a.  FileZilla connection: 192.168.26.200, amarkin, password, 22
8.  All flight plans should have a speed of 1.5 m/s and a height of 40 m.
9.  At 50 m, a path spacing of 20 m gives a 8.87 meter overlap in pointcloud imaging.
10.  Resolution of 200x200 scanlines is suitable and can always be modified in postprocessing

