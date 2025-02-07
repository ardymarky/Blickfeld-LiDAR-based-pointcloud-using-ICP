from gpiozero import LED, Button
import time
import subprocess
import datetime
import threading
from serial import Serial
from pyubx2 import UBXReader


### VARIABLES ###

# Set up GPIO pins
relay_pin = Button(16, pull_up=True)  # Relay switch
led_standby_pin = LED(25)  # Standby LED
led_recording_pin = LED(24)  # Recording LED

stop_blinking = False
blink_rate = 0.5

# Turn off LEDs initially
led_standby_pin.off()
led_recording_pin.off()


# Default GPS port and baud
ins_port = '/dev/ttyAMA0'
ins_baud = 38400
time_init = False

# Variable to track the state of the relay
relay_state = relay_pin.is_pressed

# ROS commands
record_command = "/home/LAGER/nile/logger/lidar_logger/build/CloudCap"


### FUNCTIONS ###

# Blinking LED for status
def blink_led():
    while not stop_blinking:
        led_standby_pin.toggle()
        time.sleep(blink_rate)

# When relay switch is flipped
def relay_status_change():
    # Check if relay is turned on
    if relay_pin.is_pressed:
        print("recording")
        # Start recording (execute your Python script)
        subprocess.Popen(record_command, shell=True, executable='/bin/bash')        

        led_standby_pin.off()
        led_recording_pin.on()
    else:
        print("stopped recording")
        led_recording_pin.off()
        led_standby_pin.on()
        
        subprocess.Popen(["pkill", "-f", record_command])
        
# Ping Cube 1 Lidar
def ping_ip(ip_address):
    result = subprocess.run(['ping', '-c', '1', ip_address], stdout=subprocess.PIPE)
    return result.returncode == 0

# Calculate UNIX time given GPS time
def calc_posix_time (gps_tow, gps_week, gps_leapS):
    return gps_tow/1000 + int(gps_week) * 604800 + 315964800 - gps_leapS


### MAIN CODE ###

# Start LED status indicators
led_thread = threading.Thread(target=blink_led)
led_thread.daemon = True
led_thread.start()

# Connect to Cube 1 Lidar
while ping_ip("192.168.26.26") == 0:
    print("waiting for LAN connection")
    
blink_rate = 0.1

# Open GPS stream  
stream = Serial(ins_port, ins_baud, timeout=3)

# Clear buffer
stream.reset_input_buffer()

# Read GPS stream
ubr = UBXReader(stream, protfilter=2)
(raw_data, parsed_data) = ubr.read()

# Grab time from GPS
while not time_init:

    # Only sync if data is GPS Time
    if parsed_data == None:
    
        (raw_data, parsed_data) = ubr.read()
        continue
        
    # If GPS data received    
    if parsed_data.identity == "NAV-TIMEGPS":
        print("gps connected!")
        
        # Convert GPS time to UNIX time
        cur_posix_time = calc_posix_time(parsed_data.iTOW, parsed_data.week, parsed_data.leapS)
        
        # Set System Time
        formatted_time = datetime.datetime.utcfromtimestamp(cur_posix_time).strftime('%Y-%m-%d %H:%M:%S')
        command = ['sudo', 'date', '--set', formatted_time]
        subprocess.run(command, check=True)
        time_init = True
        
    time.sleep (0.01)
    (raw_data, parsed_data) = ubr.read()

# System is on standby   
print("connected to ip address")
stop_blinking = True
led_standby_pin.on()

## MAIN LOOP ##
try:
    while True:    
        if relay_pin.is_pressed != relay_state:
            relay_state = relay_pin.is_pressed
            relay_status_change()
        
        time.sleep(0.01)
        
except KeyboardInterrupt:
    led_standby_pin.off()
    led_recording_pin.off()
