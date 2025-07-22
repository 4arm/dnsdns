#!/bin/bash

# Define the local DNS log API endpoint
LOCAL_DNS_API="http://localhost/dns.php"

# Define the remote server endpoint
REMOTE_SERVER_URL="http://203.80.23.229/dns/client_logs.php"

# Define the serial number to be sent
SERIAL_NUMBER="10000000c8788821"

echo "========================================="
echo "Starting DNS Log Sync: $(date)"
echo "========================================="
echo ""
echo "Fetching DNS log data from local server (last 24 hours)..."

# Fetch the JSON data from the local dns.php
# -s: Silent mode, -S: Show error
DNS_DATA=$(curl -s -S "${LOCAL_DNS_API}")

# Check if curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: Could not fetch data from ${LOCAL_DNS_API}. Please ensure dns.php is accessible and working."
    exit 1
fi

# Check if the fetched data is empty or contains an error (e.g., log file not found)
if echo "${DNS_DATA}" | grep -q "error"; then
    echo "Error fetching DNS data: ${DNS_DATA}"
    exit 1
fi

# Get the number of entries fetched
# This requires 'jq' to be installed (e.g., sudo apt-get install jq)
NUM_ENTRIES=$(echo "${DNS_DATA}" | jq '. | length')
echo "Fetched ${NUM_ENTRIES} log entries."

echo "Sending data to remote server..."

# Send the JSON data to the remote server using curl POST request
# -X POST: Specify POST method
# -H "Content-Type: application/json": Set the content type header
# -d @-: Read data from stdin (pipe)
# -s: Silent mode
# --output /dev/null: Discard output to prevent printing large JSON to console
RESPONSE=$(echo "${DNS_DATA}" | curl -X POST \
                -H "Content-Type: application/json" \
                -d @- \
                "${REMOTE_SERVER_URL}?serial_number=${SERIAL_NUMBER}" \
                -s)

# Check if the POST request was successful
if [ $? -ne 0 ]; then
    echo "Error: Could not send data to ${REMOTE_SERVER_URL}. Please check network connectivity and remote server status."
    exit 1
fi

# The following line prints the server's response.
# If you don't want to see the JSON output, you can comment it out or remove it.
# echo "Data sent to remote server. Server response:"
# echo "${RESPONSE}"

echo ""
echo "========================================="
echo "DNS Log Sync Finished: $(date)"
echo "========================================="
