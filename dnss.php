<?php
$logFile = "/var/log/dnsmasq.log";  // Adjust path

if (!file_exists($logFile)) {
    echo json_encode(["error" => "Log file not found"]);
    exit;
}

$client_ips = [];

$lines = file($logFile);
foreach ($lines as $line) {
    if (preg_match('/query.* from ([\d\.]+)/', $line, $matches)) {
        $ip = $matches[1];
        $client_ips[$ip] = true;
    }
}

$unique_count = count($client_ips);
$ip_list = array_keys($client_ips);

header('Content-Type: application/json');
echo json_encode([
    "unique_client_count" => $unique_count,
    "clients" => $ip_list
]);
?>
