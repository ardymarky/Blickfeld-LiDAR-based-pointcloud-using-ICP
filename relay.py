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

# Function to execute additional actions (e.g., start/stop recording)
def execute_additional_actions():
    global recording_process
    # Check if relay is turned on
    if GPIO.input(relay_pin) == GPIO.HIGH:
        print("Relay switched ON. Starting recording...")
        # Start recording (execute your Python script)
        # recording_process = subprocess.Popen(["python3", "your_script.py"])
    else:
        print("Relay switched OFF. Stopping recording...")
        # Stop recording (terminate the Python script if it's running)
        # recording_process.terminate()

def ping_ip(ip_address):
    result = subprocess.run(['ping', '-c', '1', ip_address], stdout=subprocess.PIPE)
    return result.returncode == 0

while ping_ip("192.168.26.26") == 0:
    print("waiting for LAN connection")
    time.sleep(5)

print("connected to ip address)
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
