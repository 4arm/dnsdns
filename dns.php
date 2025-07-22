<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
header('Content-Type: application/json');

// Set the default timezone to match the server's local time where dnsmasq logs are generated.
// This is crucial for accurate timestamp comparisons.
// Assuming the server is in Kuala Lumpur, Malaysia (+08:00).
date_default_timezone_set('Asia/Kuala_Lumpur');

$logFile = '/var/log/dnsmasq.log';
if (!file_exists($logFile)) {
    echo json_encode(["error" => "Log file not found"]);
    exit;
}

// Read all lines from the log file, ignoring empty lines.
$lines = file($logFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
if ($lines === false) {
    echo json_encode(["error" => "Could not read log file."]);
    exit;
}

// Calculate the timestamp for 24 hours ago.
// This uses the current time in the timezone set above.
$twentyFourHoursAgo = time() - (24 * 3600);

$filteredLines = [];
foreach ($lines as $line) {
    // Attempt to parse the timestamp from the beginning of the line.
    // dnsmasq log format example: "Jul 21 11:19:54"
    if (preg_match('/^(\w+\s+\d+\s[\d:]+)/', $line, $matches)) {
        $logDateTimeStr = $matches[1];
        $currentYear = date('Y'); // Get the current year

        // Try parsing the log timestamp by appending the current year.
        $logTimestamp = strtotime($logDateTimeStr . ' ' . $currentYear);

        // Handle year transition: If the parsed timestamp is in the future,
        // it means the log entry is likely from the previous year (e.g., a log
        // from December 31st when the current date is January 1st).
        if ($logTimestamp !== false && $logTimestamp > time()) {
            $logTimestamp = strtotime($logDateTimeStr . ' ' . ($currentYear - 1));
        }

        // Only include lines where the timestamp was successfully parsed
        // and is within the last 24 hours.
        if ($logTimestamp !== false && $logTimestamp >= $twentyFourHoursAgo) {
            $filteredLines[] = $line;
        }
    }
}

// The lines to process are now only those within the last 24 hours.
$linesToProcess = $filteredLines;

/**
 * Provides a human-readable explanation for a dnsmasq log line.
 * This function uses 'str_contains' for simple keyword matching.
 *
 * @param string $line The full dnsmasq log line.
 * @return string A descriptive explanation of the log entry.
 */
function explainDnsmasq($line) {
    return match (true) {
        str_contains($line, 'from /etc/hosts') => 'Answered from /etc/hosts file.',
        str_contains($line, 'from dhcp-host') => 'Answered from DHCP hostname mapping.',
        str_contains($line, 'from cache') => 'Answered from internal cache.',
        str_contains($line, 'forwarded') => 'Query forwarded to upstream DNS.',
        str_contains($line, 'query[A]') => 'New IPv4 (A) query from client.',
        str_contains($line, 'query[AAAA]') => 'New IPv6 (AAAA) query from client.',
        str_contains($line, 'reply') && str_contains($line, 'is') => 'Received reply for DNS query.',
        str_contains($line, 'is NODATA') => 'Domain exists but no record of requested type.',
        str_contains($line, 'is NXDOMAIN') => 'Domain does not exist (NXDOMAIN).',
        str_contains($line, 'config') => 'Answered from static dnsmasq config.',
        str_contains($line, 'bogus-nxdomain') => 'Blocked bogus NXDOMAIN response.',
        str_contains($line, 'ignored nameserver') => 'Ignored own nameserver to prevent loop.',
        str_contains($line, 'possible DNS-rebind') => 'Possible DNS rebinding attack detected.',
        str_contains($line, 'refused') => 'Upstream DNS refused the query.',
        str_contains($line, 'no such host') => 'Host not found.',
        str_contains($line, 'DHCPDISCOVER') => 'DHCP Discover received.',
        str_contains($line, 'DHCPOFFER') => 'Offered DHCP lease to client.',
        str_contains($line, 'DHCPREQUEST') => 'DHCP Request from client.',
        str_contains($line, 'DHCPACK') => 'DHCP IP assigned and acknowledged.',
        str_contains($line, 'DHCPNAK') => 'DHCP request declined.',
        str_contains($line, 'cached') => 'DHCP lease cached.',
        str_contains($line, '<CNAME>') => 'CNAME',
        default => 'General log entry.'
    };
}

$data = [];

foreach ($linesToProcess as $line) {
    // Regex to parse various dnsmasq log formats and extract specific fields.
    // This regex is designed to be flexible with optional parts.
    // Captured groups:
    // 1: time (e.g., "Jul 21 11:19:54")
    // 2: id (optional, e.g., query ID)
    // 3: client_ip (optional)
    // 4: port (optional)
    // 5: action (optional, e.g., 'query', 'reply')
    // 6: domain (optional)
    // 7: forwarded_to (optional, IP address)
    // 8: reply (optional, e.g., "is 192.168.1.1")
    if (preg_match('/^(\w+\s+\d+\s[\d:]+)\s+dnsmasq\[\d+\]:\s+(?:(\d+)?\s*)?([\d.]+)?(?:\/(\d+))?\s*(\w+)?\s*([^\s]+)?(?:\s+to\s+([\d.]+))?(?:\s+is\s+(.+))?/', $line, $matches)) {
        $data[] = [
            "time" => $matches[1] ?? '',
            "id" => $matches[2] ?? '',
            "client_ip" => $matches[3] ?? '',
            "port" => $matches[4] ?? '',
            "action" => $matches[5] ?? '',
            "domain" => $matches[6] ?? '',
            "forwarded_to" => $matches[7] ?? '',
            "reply" => $matches[8] ?? '',
            "info" => explainDnsmasq($line) // Get human-readable info for the log line
        ];
    }
}

// Reverse the order of the data array so the latest entries appear first.
$data = array_reverse($data);

// Output the processed data as JSON.
echo json_encode($data);
?>
