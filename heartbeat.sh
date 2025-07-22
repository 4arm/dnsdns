#!/bin/bash

# CONFIG
SERIAL_NUMBER="10000000c8788821"
SERVER="http://203.80.23.229/dns/update_ip.php"  # Your backend server

# GET PUBLIC IP
PUBLIC_IP=$(curl -s https://api.ipify.org)

# GET DNS CLIENT DATA FROM LOCAL SERVER (dnsmasq stats)
DNS_API="http://localhost/dnss.php"
DNS_DATA=$(curl -s "$DNS_API")

# Check if DNS_DATA contains the expected key
HAS_CLIENT_DATA=$(echo "$DNS_DATA" | grep -q "unique_client_count" && echo "yes" || echo "no")

# Post data to remote server and capture response
if [ "$HAS_CLIENT_DATA" = "yes" ]; then
    RESPONSE=$(curl -s -X POST \
        -d "serial_number=$SERIAL_NUMBER" \
        -d "public_ip=$PUBLIC_IP" \
        --data-urlencode "dns_data=$DNS_DATA" \
        "$SERVER")
else
    RESPONSE=$(curl -s -X POST \
        -d "serial_number=$SERIAL_NUMBER" \
        -d "public_ip=$PUBLIC_IP" \
        "$SERVER")
fi

echo "Server response: $RESPONSE"
