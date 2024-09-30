import RPi.GPIO as GPIO
import time
import subprocess
import datetime
from serial import Serial
from pyubx2 import UBXReader

# Set up GPIO using BCM numbering
GPIO.setmode(GPIO.BCM)

# Set up GPIO pin as an input
relay_pin = 16
GPIO.setup(relay_pin, GPIO.IN)

# Default port and baud
ins_port = '/dev/ttyAMA0'
ins_baud = 38400
time_init = False

# Variable to track the state of the relay
relay_state = GPIO.input(relay_pin)

record_command = "ros2 component standalone blickfeld_driver blickfeld::ros_interop::BlickfeldDriverComponent -p host:=192.168.26.26"

save_command = '''ros2 bag record /bf_lidar/point_cloud_out -o "$(date '+%H:%M %F') Scan"'''

# Function to execute additional actions (e.g., start/stop recording)
def execute_additional_actions():

    # Check if relay is turned on
    if GPIO.input(relay_pin) == GPIO.HIGH:
        print("recording")
        # Start recording (execute your Python script)
        subprocess.Popen(record_command, shell=True, executable='/bin/bash')
        time.sleep(10)
        
        print("saving")
        subprocess.Popen(save_command, shell=True)
        
    else:
    
        # Stop recording (terminate the Python script if it's running)
        print("stopped recording")
        subprocess.Popen(["pkill", "-f", save_command])
        
        time.sleep(2)
        
        subprocess.Popen(["pkill", "-f", record_command])

def ping_ip(ip_address):
    result = subprocess.run(['ping', '-c', '1', ip_address], stdout=subprocess.PIPE)
    return result.returncode == 0

# Calculate UNIX time given GPS time
def calc_posix_time (gps_tow, gps_week, gps_leapS):
    return gps_tow/1000 + int(gps_week) * 604800 + 315964800 - gps_leapS

# Open serial port to Hadron 640-r  
stream = Serial(ins_port, ins_baud, timeout=3)
# Clear buffer
stream.reset_input_buffer()


ubr = UBXReader(stream, protfilter=2)
(raw_data, parsed_data) = ubr.read()

while not time_init:
    # Only sync if data is GPS Time
    if parsed_data.identity == "NAV-TIMEGPS":
        print("gps connected!")
        
        # Convert GPS time to UNIX time
        cur_posix_time = calc_posix_time(parsed_data.iTOW, parsed_data.week, parsed_data.leapS)-18000
        
        # Set System Time
        formatted_time = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(cur_posix_time))
        command = ['sudo', 'date', '--set', formatted_time]
        subprocess.run(command, check=True)
        #time.clock_settime(time.CLOCK_REALTIME, cur_posix_time)
        time_init = True

    time.sleep (0.001) # Limit how fast the loop runs
    (raw_data, parsed_data) = ubr.read()

    
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
