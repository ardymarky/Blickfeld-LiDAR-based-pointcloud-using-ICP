# Blickfeld pointcloud data collection and processing

This repository documents the process of setting up a Blickfeld Outdoor Cube 1 LiDAR system to record and visualize pointcloud data through C++ and ROS2. This in an ongoing project by LAGER and Nucor, and led by Arden Markin.

[Blickfeld Cube 1 Manual](https://www.blickfeld.com/wp-content/uploads/2022/10/Blickfeld-A5-Manual_en_v.4.2.pdf)

## Select Platform

<details>
<summary>C++ & RPI4 IOS</summary>

### C++ & RPI4 IOS

#### Configuration steps
1.  Install RPI4 IOS
2.  Install BSL
3.  System Setup
    * Static IP address
    * GPS
    * LED indicators
    * HDMI on boot
    * Execute on system boot
    * Enable SSH
4.  Capture LiDAR data
5.  Post-process PointCloud in Matlab

### Step 1: Install RPI4 IOS

Download and open the Raspberry Pi Imager [here](https://www.raspberrypi.com/software/)

Select the RPI4 device and Rasbian operating system. Insert and select the SD card to flash the image to. Once complete, insert the SD card into the RPI4.

### Step 2: Blickfeld Standard Library

[Blickfeld Driver](https://www.blickfeld.com/resources/) \
[Installation Process](https://docs.blickfeld.com/cube/latest/external/blickfeld-scanner-lib/install.html)

To install BSL, build it from source WITH installed dependencies. Install protoc buffers and cmake via available packages. The following lines should be all you need.

```console
sudo apt update
sudo apt install -y cmake git build-essential libprotobuf-dev libprotoc-dev protobuf-compiler
sudo apt update
git clone --recursive https://github.com/Blickfeld/blickfeld-scanner-lib.git
mkdir blickfeld-scanner-lib/build && cd blickfeld-scanner-lib/build
cmake ..
make -j3
sudo make install
```

### Step 3: System Setup

#### Static IP Address

To connect to the blickfeld over a network switch, the ethernet adapter must be configured to a static ip address. In the terminal, run `ip addr` and identify the name of the ethernet cable (should be eth0). 

Create a new network file: `sudo nano /etc/systemd/network/eth0.network` and add these contents

```network
[Match]
Name=eth0

[Network]
Address=192.168.26.xxx/24
DNS=8.8.8.8 8.8.4.4
DHCP=ipv4
Optional=true
```

Replace `xxx` with any port number that is not 0, 255, or 26. Replace `eth0` with the name of the ethernet cable if different.
To permanently apply these changes run 

```console
sudo systemctl restart systemd-networkd
sudo systemctl enable systemd-networkd
```

#### Pip Install

Installing through pip has proven jank at times so instead of a requirements.txt, here are all the libraries you will need to properly run relay_rpi.py:

```console
pip3 install --break-system-packages pyubx2
pip3 install gpiozero --break-system-packages
```

#### GPS over UART

Breakout the UART's TX and ground cables, and connect them to pins 6 and 10 (GPIO 15) respectively. Ensure your GPS receiver is sending UBX-NAV-TIMEGPS messages. Should the RPI4 successfully connect to the receiver, the system time should be correctly set and the led indicator light will turn green. Each subsequent recorded BAG file with then be time stamped in the following format: `Hour:Minute Month/Day/Year Scan`

To ensure the system boots without interfernce over UART, run `sudo nano /boot/firmware/config.txt` and add/change lines:

```console
#dtoverlay=disable-bt
enable_uart=0
```

Remove `console=serial-,115200` and `console=ttyS0,115200` from `/boot/firmware/cmdline.txt` if present.

Finally, run disable serial console and reboot:
```console
sudo systemctl disable serial-getty@ttyS0.service
sudo systemctl stop serial-getty@ttyS0.service
sudo reboot
```

#### LED indicators

To assist the operator in tracking the status of the system without the need to remote-in or an external monitor, LED indicator lights were used. Connect the red LED to pin 22 (GPIO 25) and the green LED to pin 18 (GPIO 24). Connect their ground to pin 20. The RPI4 outputs a voltage of 3.3V to each LED.

| Color    | Behavior | Status |
| -------- | ------- | ------- |
| Red  | Slow blinking    | Searching for LiDAR |
| Red  | Rapid blinking    | Searching for GPS |
| Red  | Solid  | System is ready/standby |
| Green  | Solid   | Recording/Saving |

#### HDMI on boot

If no HDMI is plugged into the RPI4, relay.py will not automatically run for some reason. To work around this issue, configure `boot/firmware/config.txt` to always output HDMI even if no output source is detected.

```console
# Force HDMI even if no monitor is detected
hdmi_force_hotplug=1

# Uncomment if you have trouble with the Pi detecting your display or outputting
# hdmi_safe=1
# hdmi_ignore_edid=0xa5000080
```
#### Execute on system boot

Because the python script uses a subprocess/new terminal to execute ROS commands, crontab can't properly execute the commands. Instead, simply add the command `/usr/bin/python3 /path/to/relay_boot.py/file in <strong>Startup Applications</strong>.

#### SSH through LAN

[SSH/LAN Docs](https://serverastra.com/docs/Tutorials/Setting-Up-and-Securing-SSH-on-Ubuntu-22.04%3A-A-Comprehensive-Guide) \
[FileZilla](https://filezilla-project.org/)

To setup SSH through the network switch over LAN, follow the steps in the link above. To transfer files, connect a laptop to the network switch and run FileZilla or any other file transfering application.
Should it not connect through LAN, check the laptop's ethernet cable connection, manually setting the subnet to `192.168.26.X` and the mask to `255.255.255.0` if necessary.

Also you may need to uncomment: `PasswordAuthentication yes` in `/etc/ssh/sshd_config` to login.

### Step 4: Capture Data

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

### Step 5: Matlab ICP

To post-process the bag file taken from the Blickfeld, the Matlab ICP Map Builder is used.

[Matlab Guide](https://www.mathworks.com/help/driving/ug/build-a-map-from-lidar-data.html) \
[Matlab Install](https://www.mathworks.com/help/install/install-products.html)

Open Matlab and run `pointcloudparser.m`, modifying the file as required. This will parse the Ros2 PointCloud into a format Matlab can understand. Once the script finishes running, run `icpsolver.m`. This will output a combined PointCloud as a `.ply` file.

Should Matlab throw the error `'helperLidarMapBuilder' is used in the following examples...`, download `helperLidarMapBuilder.m` and add it to the current directory.

### Extra Steps / Miscellaneous Details

#### Relay Switch

Running `relay.py` on boot gives the LiDAR system a relay switch that either starts or stops the recording process. When the relay is on, data is being saved to a ros2 bagfile.

</details>
<details>
<summary>ROS2 & Ubuntu</summary>

### Ubuntu

#### Configuration steps
1.  Install Ubuntu 20.04 on RPI4
2.  Install BSL and Blickfeld Driver
3.  Install Ros2 Foxy
4.  System Setup
    * Static IP address
    * Pip install
    * GPS
    * LED indicators
    * HDMI on boot
    * Execute on system boot
    * Enable SSH
5.  Capture LiDAR data
6.  Post-process PointCloud in Matlab

### Step 1: Install Ubuntu 20.04 on RPI4

Download and open the Raspberry Pi Imager [here](https://www.raspberrypi.com/software/)

Select the RPI4 device and Ubuntu 20.04 LTS 64-bit operating system. Insert and select the SD card to flash the image to. Once complete, insert the SD card into the RPI4. After the system boots, run these commands:

```console
sudo apt install ubuntu-desktop
sudo reboot
```

### Step 2: Install ROS2 Foxy

[Ros2 Foxy Docs](https://docs.ros.org/en/foxy/Installation/Ubuntu-Install-Debians.html)

The Cube 1's provided ROS driver requires the Ros2 Foxy Distro. Should the system architecture not match, build from source (likely unnecessary).

### Step 3: BSL and Blickfeld Driver Setup

[Blickfeld Driver](https://www.blickfeld.com/resources/) \
[Installation Process](https://docs.blickfeld.com/cube/latest/external/ros/driver-v2/README.html)

To install BSL, build it from source WITH installed dependencies. Install protoc buffers and cmake via available packages. The following lines should be all you need.

```console
sudo apt update
sudo apt install -y cmake git build-essential libprotobuf-dev libprotoc-dev protobuf-compiler
sudo apt update
git clone --recursive https://github.com/Blickfeld/blickfeld-scanner-lib.git
mkdir blickfeld-scanner-lib/build && cd blickfeld-scanner-lib/build
cmake ..
make -j3
sudo make install
```

Next, install the blickfeld ROS2 driver. Before building using "colcon", make sure to extract the driver and move it to the /${workspace}/src directory.

IMPORTANT: double check the Cube1 for its BSL version dependency. If neccessary, you may have to checkout an older branch before compiling BSL. BSL version history can be found [here](https://github.com/Blickfeld/blickfeld-scanner-lib/releases). Replace ba53a9d with the desired branch/release.

```console
cd /${BSL_directory}
git checkout ba53a9d
```

### Step 4: System Setup

#### Static IP Address

[Documentation](https://docs.blickfeld.com/cube/latest/getting_started)

To connect to the blickfeld over a network switch, the ethernet adapter must be configured to a static ip address. In the terminal, run `ip addr` and identify the name of the ethernet cable (should be eth0). 
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

#### Pip Install

Installing through pip has proven jank at times so instead of a requirements.txt, here are all the libraries you will need to properly run relay_rpi.py:

```console
pip3 install pyubx2
pip3 install RPi.GPIO
```

#### GPS over UART

To get GPS working over UART, U-boot must be configured manually so that serial console isn't corrupted by the new serial uart on boot. Follow the steps [avaiable here.](https://raspberrypi.stackexchange.com/questions/116074/how-can-i-disable-the-serial-console-on-distributions-that-use-u-boot/117950#117950)

Breakout the GPS UART's TX and ground cables, and connect them to pins 6 and 10 (GPIO 15) respectively. Ensure your GPS receiver is sending UBX-NAV-TIMEGPS messages. Should the RPI4 successfully connect to the receiver, the system time should be correctly set and the led indicator light will turn green. Each subsequent recorded BAG file with then be time stamped in the following format: `Hour:Minute Month/Day/Year Scan`

#### LED indicators

To assist the operator in tracking the status of the system without the need to remote-in or an external monitor, LED indicator lights were used. Connect the red LED to pin 22 (GPIO 25) and the green LED to pin 18 (GPIO 24). Connect their ground to pin 20. The RPI4 outputs a voltage of 3.3V to each LED.

| Color    | Behavior | Status |
| -------- | ------- | ------- |
| Red  | Slow blinking    | Searching for LiDAR |
| Red  | Rapid blinking    | Searching for GPS |
| Red  | Solid  | System is ready/standby |
| Green  | Solid   | Recording/Saving |

#### HDMI on boot

If no HDMI is plugged into the RPI4, relay.py will not automatically run for some reason. To work around this issue, configure `boot/firmware/config.txt` to always output HDMI even if no output source is detected.

```console
# Force HDMI even if no monitor is detected
hdmi_force_hotplug=1

# Uncomment if you have trouble with the Pi detecting your display or outputting
# hdmi_safe=1
# hdmi_ignore_edid=0xa5000080
```
#### Execute on system boot

Because the python script uses a subprocess/new terminal to execute ROS commands, crontab can't properly execute the commands. Instead, simply add the command `/usr/bin/python3 /path/to/relay_boot.py/file in <strong>Startup Applications</strong>.

#### SSH through LAN

[SSH/LAN Docs](https://serverastra.com/docs/Tutorials/Setting-Up-and-Securing-SSH-on-Ubuntu-22.04%3A-A-Comprehensive-Guide) \
[FileZilla](https://filezilla-project.org/)

To setup SSH through the network switch over LAN, follow the steps in the link above. To transfer files, connect a laptop to the network switch and run FileZilla or any other file transfering application.
Should it not connect through LAN, check the laptop's ethernet cable connection, manually setting the subnet to `192.168.26.X` and the mask to `255.255.255.0` if necessary.

Also you may need to uncomment: `PasswordAuthentication yes` in `/etc/ssh/sshd_config` to login.

### Step 4: Capture Data

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

### Step 5: Matlab ICP

To post-process the bag file taken from the Blickfeld, the Matlab ICP Map Builder is used.

[Matlab Guide](https://www.mathworks.com/help/driving/ug/build-a-map-from-lidar-data.html) \
[Matlab Install](https://www.mathworks.com/help/install/install-products.html)

Open Matlab and run `pointcloudparser.m`, modifying the file as required. This will parse the Ros2 PointCloud into a format Matlab can understand. Once the script finishes running, run `icpsolver.m`. This will output a combined PointCloud as a `.ply` file.

Should Matlab throw the error `'helperLidarMapBuilder' is used in the following examples...`, download `helperLidarMapBuilder.m` and add it to the current directory.

### Extra Steps / Miscellaneous Details

#### Relay Switch

Running `relay.py` on boot gives the LiDAR system a relay switch that either starts or stops the recording process. When the relay is on, data is being saved to a ros2 bagfile.

</details>

# Video Streaming via DoodleLabs

To see what we are scanning, a RPI camera is incorporated into the system. The live feed is fed through Gstreamer to a DoodleLabs module connnected to the network switch.

First install gstreamer:
```console
sudo apt update
sudo apt install -y gstreamer1.0-tools gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-libav \
    gstreamer1.0-omx gstreamer1.0-rtsp gstreamer1.0-pulseaudio
```

Edit `/boot/firmware/config.txt` and reboot:

```console
gpu_mem=256
dtoverlay=vc4-kms-v3d
dtoverlay=imx477
```

To view camera footage, run `gst-launch-1.0 v4l2src device=/dev/video0 ! videoconvert ! autovideosink` (untested)

To stream camera footage, run `gst-launch-1.0 v4l2src device=/dev/video0 ! videoconvert ! x264enc tune=zerolatency bitrate=5000 speed-preset=superfast ! rtph264pay ! udpsink host=10.223.168.1 port=5001 sync=false` (untested)

Ensure doodlelabs is connected through the network switch. Once camera footage is streaing on the receiving host, run `gst-launch-1.0 udpsrc port=5001 caps="application/x-rtp,media=video,clock-rate=90000,encoding-name=H264" ! rtph264depay ! avdec_h264 ! videoconvert ! autovideosink sync=false` to view.


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

