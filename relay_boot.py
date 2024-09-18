import RPi.GPIO as GPIO
import time
import subprocess

# Set up GPIO using BCM numbering
GPIO.setmode(GPIO.BCM)

# Set up GPIO pin as an input
relay_pin = 16  # Change this to match your wiring
GPIO.setup(relay_pin, GPIO.IN)

# Variable to track the state of the relay
relay_state = GPIO.input(relay_pin)

ros2_command = "ros2 component standalone blickfeld_driver blickfeld::ros_interop::BlickfeldDriverComponent -p host:=192.168.26.26 -p publish_imu:=true -p publish_imu_static_tf_at_start:=true"

save_command = "ros2 bag record /bf_lidar/point_cloud_out /bf_lidar/imu_out"

# Function to execute additional actions (e.g., start/stop recording)
def execute_additional_actions():

    # Check if relay is turned on
    if GPIO.input(relay_pin) == GPIO.HIGH:
        print("recording")
        # Start recording (execute your Python script)
        subprocess.Popen(ros2_command, shell=True, executable='/bin/bash')
        time.sleep(10)
        
        print("saving")
        subprocess.Popen(save_command, shell=True)
        
    else:
    
        # Stop recording (terminate the Python script if it's running)
        print("stopped recording")
        subprocess.Popen(["pkill", "-f", save_command])
        
        time.sleep(2)
        
        subprocess.Popen(["pkill", "-f", ros2_command])

def ping_ip(ip_address):
    result = subprocess.run(['ping', '-c', '1', ip_address], stdout=subprocess.PIPE)
    return result.returncode == 0

while ping_ip("192.168.26.26") == 0:
    print("waiting for LAN connection")
    
print("connected to ip address")
try:
    while True:    
        # Check the state of the GPIO pin
        if GPIO.input(relay_pin) != relay_state:
            # Relay state has changed
            relay_state = GPIO.input(relay_pin)
            execute_additional_actions()
                
        # Add any additional actions or processing here
        
        time.sleep(0.1)  # Add a short delay to reduce CPU usage
        
except KeyboardInterrupt:
    # Clean up GPIO on keyboard interrupt
    GPIO.cleanup()
