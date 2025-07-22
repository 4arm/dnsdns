import paho.mqtt.client as mqtt
import json
import requests
import time
from datetime import datetime
import pytz

# === Malaysia timezone timestamp ===
def get_malaysia_timestamp():
    malaysia = pytz.timezone('Asia/Kuala_Lumpur')
    return datetime.now(malaysia).replace(microsecond=0).isoformat()

# === Get public IP ===
def get_public_ip():
    try:
        return requests.get("https://ipv4.icanhazip.com", timeout=5).text.strip()
    except Exception as e:
        print(f"[!] Failed to get public IP: {e}")
        return "0.0.0.0"

# === Get Serial Number from /proc/cpuinfo ===
def get_serial_number():
    try:
        with open('/proc/cpuinfo', 'r') as f:
            for line in f:
                if line.startswith('Serial'):
                    return line.strip().split(":")[1].strip()
    except Exception as e:
        print(f"[!] Failed to read serial number: {e}")
    return "UNKNOWN"

# === Device Info Payload ===
serial_number = get_serial_number()
DEVICE_INFO = {
    "timestamp": get_malaysia_timestamp(),
    "serial_number": serial_number,
    "public_ip": get_public_ip()
}

# === MQTT Setup ===
MQTT_BROKER = "203.80.23.229"
MQTT_PORT = 1883
MQTT_TOPIC = "dns/registration"
MQTT_USERNAME = "mqttuser"
MQTT_PASSWORD = "Muhd2003@"

client = mqtt.Client(client_id="dns-" + serial_number)
client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)

# === MQTT Connect + Publish with Retry ===
success = False
for attempt in range(3):
    try:
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.publish(MQTT_TOPIC, json.dumps(DEVICE_INFO), qos=1)
        print(f"[+] Attempt {attempt+1}: Sent device info:", DEVICE_INFO)
        client.disconnect()
        success = True
        break
    except Exception as e:
        print(f"[!] MQTT attempt {attempt+1} failed: {e}")
        time.sleep(2)

if not success:
    print("[!] All MQTT attempts failed. Consider logging locally.")
