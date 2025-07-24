test2.sh
#!/bin/bash
set -o pipefail

# === CONFIG =====================================================
LOCAL_DNS_API="http://localhost/dns.php"
REMOTE_SERVER_URL="http://203.80.23.229/dns/client_logs.php"
SERIAL_NUMBER="13598b414d593714"
JQ_BIN=$(command -v jq || echo "")

# === LOG HEADER =================================================
echo "========================================="
echo "Starting DNS Log Sync: $(date)"
echo "========================================="
echo

echo "Fetching DNS log data from local server (last 24 hours)..."

# Fetch JSON from local API
if ! DNS_DATA=$(curl -sS --fail "${LOCAL_DNS_API}"); then
    echo "Error: Could not fetch data from ${LOCAL_DNS_API}. Ensure dns.php is reachable."
    exit 1
fi

# Basic non-empty check
if [[ -z "$DNS_DATA" ]]; then
    echo "Error: Local API returned empty response."
    exit 1
fi

# Validate JSON
if [[ -n "$JQ_BIN" ]]; then
    if ! echo "$DNS_DATA" | jq -e . >/dev/null 2>&1; then
        echo "Error: Local API returned invalid JSON:"
        echo "$DNS_DATA"
        exit 1
    fi
    NUM_ENTRIES=$(echo "$DNS_DATA" | jq 'length')
else
    echo "Warning: jq not found; skipping JSON validation and count."
    NUM_ENTRIES="unknown"
fi

echo "Fetched ${NUM_ENTRIES} log entries."

echo
echo "Sending data to remote server..."

# Use a subshell pipe to preserve stdin. Capture HTTP code separately.
HTTP_CODE=$(
    echo "$DNS_DATA" | curl -sS \
        --fail-with-body \
        -X POST \
        -H "Content-Type: application/json" \
        --data-binary @- \
        "${REMOTE_SERVER_URL}?serial_number=${SERIAL_NUMBER}" \
        -w "%{http_code}" \
        -o /tmp/test_dns_resp_body.$$
)

CURL_STATUS=$?
RESP_BODY="$(cat /tmp/test_dns_resp_body.$$ 2>/dev/null)"
rm -f /tmp/test_dns_resp_body.$$ || true

if [[ $CURL_STATUS -ne 0 ]]; then
    echo "Error: curl failed sending data to remote server."
    echo "curl exit status: $CURL_STATUS"
    echo "HTTP code (if any): $HTTP_CODE"
    echo "Response body:"
    echo "$RESP_BODY"
    exit 1
fi

# Check HTTP status
if [[ "$HTTP_CODE" != "200" ]]; then
    echo "Remote server returned HTTP $HTTP_CODE."
    echo "Response body:"
    echo "$RESP_BODY"
    exit 1
fi

echo "Data sent successfully."
echo "Server response:"
echo "$RESP_BODY"
echo

echo "========================================="
echo "DNS Log Sync Finished: $(date)"
echo "========================================="
