#!/bin/bash

# Output file
OUTPUT_FILE="/etc/bind/whitelist.conf"

# MySQL credentials (change these accordingly)
MYSQL_USER="izham"
MYSQL_PASS="Muhd2003@"
MYSQL_DB="dns_database"

# Start the ACL block
echo 'acl "allowed-clients" {' > "$OUTPUT_FILE"

# Fetch public_ip from MySQL, add semicolon, and indent each line
mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -D "$MYSQL_DB" -e \
"SELECT public_ip FROM device;" -B -N | sed 's/^/    /; s/$/;/' >> "$OUTPUT_FILE"

# Close the ACL block
echo "};" >> "$OUTPUT_FILE"

# Reload BIND configuration
echo "Reloading BIND configuration..."
sudo rndc reload

# Restart BIND using systemctl
echo "Restarting BIND service with systemctl (bind)..."
sudo systemctl restart bind

# Restart BIND using systemctl (named)
echo "Restarting BIND service with systemctl (named)..."
sudo systemctl restart named
