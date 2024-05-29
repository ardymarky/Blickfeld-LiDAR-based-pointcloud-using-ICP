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

combined_command = "source blickfeld/install/setup.bash && " + ros2_command + " && echo hi"
save_command = "source blickfeld/install/setup.bash && ros2 bag record /bf_lidar/point_cloud_out /bf_lidar/imu_out" + " && echo hi"

# Function to execute additional actions (e.g., start/stop recording)
def execute_additional_actions():

    # Check if relay is turned on
    if GPIO.input(relay_pin) == GPIO.HIGH:
        print("Relay switched ON. Starting recording...")
        # Start recording (execute your Python script)
        subprocess.Popen(["gnome-terminal", "--", "bash", "-c", combined_command])
        time.sleep(10)
        print("Starting to save...")
        subprocess.Popen(["gnome-terminal", "--", "bash", "-c", save_command])
    else:
        print("Relay switched OFF. Stopping recording...")
        # Stop recording (terminate the Python script if it's running)
        
        subprocess.run(["pkill", "-f", save_command])
        time.sleep(2)
        print("Killing scanner")
        subprocess.run(["pkill", "-f", combined_command])

def ping_ip(ip_address):
    result = subprocess.run(['ping', '-c', '1', ip_address], stdout=subprocess.PIPE)
    return result.returncode == 0

while ping_ip("192.168.26.26") == 0:
    print("waiting for LAN connection")
    with open('/sys/class/leds/led0/brightness', 'w') as file:
        file.write('1')

print("connected to ip address")
try:
    while True:    
        with open('/sys/class/leds/led0/brightness', 'w') as file:
            file.write('1')
    # Check the state of the GPIO pin
        if GPIO.input(relay_pin) != relay_state:
            # Relay state has changed
            relay_state = GPIO.input(relay_pin)
            execute_additional_actions()
            
        if GPIO.input(relay_pin) == GPIO.HIGH:
            with open('/sys/class/leds/led0/brightness', 'w') as file:
                file.write('0')
        
        # Add any additional actions or processing here
        
        time.sleep(0.1)  # Add a short delay to reduce CPU usage
        
except KeyboardInterrupt:
    # Clean up GPIO on keyboard interrupt
    GPIO.cleanup()
