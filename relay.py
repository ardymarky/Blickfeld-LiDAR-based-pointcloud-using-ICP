import RPi.GPIO as GPIO
import time
import subprocess

# Set up GPIO using BCM numbering
GPIO.setmode(GPIO.BCM)

# Set up GPIO pin as an input
relay_pin = 17  # Change this to match your wiring
GPIO.setup(relay_pin, GPIO.IN)

# Variable to track the state of the relay
relay_state = GPIO.input(relay_pin)

# Bash commands to run when relay state is changed
scan_command = "source blickfeld/install/setup.bash && ros2 component standalone blickfeld_driver blickfeld::ros_interop::BlickfeldDriverComponent -p host:=192.168.26.26 && echo hi"
save_command = "source blickfeld/install/setup.bash && ros2 bag record /bf_lidar/point_cloud_out && echo hi"

# Function to execute additional actions (e.g., start/stop recording)
def execute_additional_actions():

    # Check if relay is turned on
    if GPIO.input(relay_pin) == GPIO.HIGH:
        # Start recording
        print("Relay switched ON. Starting recording...")
        subprocess.Popen(["gnome-terminal", "--", "bash", "-c", scan_command])
        time.sleep(10)
        print("Starting to save...")
        subprocess.Popen(["gnome-terminal", "--", "bash", "-c", save_command])
    else:
        # Stop recording and terminate python scripts
        print("Relay switched OFF. Stopping recording...")
        subprocess.run(["pkill", "-f", save_command])
        time.sleep(2)
        print("Killing scanner")
        subprocess.run(["pkill", "-f", scan_command])

# Function to ping blickfeld
def ping_ip(ip_address):
    result = subprocess.run(['ping', '-c', '1', ip_address], stdout=subprocess.PIPE)
    return result.returncode == 0

# Check if blickfeld is online
while ping_ip("192.168.26.26") == 0:
    print("waiting for LAN connection")
    # Blinking light when searching
    with open('/sys/class/leds/led0/brightness', 'w') as file:
        file.write('1')

print("connected to ip address")
try:
    while True:    
        # Solid light when connected
        with open('/sys/class/leds/led0/brightness', 'w') as file:
            file.write('1')
            
        # Check the state of the GPIO pin
        if GPIO.input(relay_pin) != relay_state:
            # Relay state has changed
            relay_state = GPIO.input(relay_pin)
            execute_additional_actions()
            
        time.sleep(0.1)  # Add a short delay to reduce CPU usage
        
except KeyboardInterrupt:
    # Clean up GPIO on keyboard interrupt
    GPIO.cleanup()
