#!/bin/sh
set -e

SCRIPT_DIR=$(pwd)
cd "$SCRIPT_DIR"

read -p "Enter a hostname or press Enter for default(k2plus): " HOSTNAME
HOSTNAME="${HOSTNAME:-k2plus}"

sed -i "s#hostname = \"k2plus\"#hostname = \"$HOSTNAME\"#" "$SCRIPT_DIR/mdns_responder.py"
sed -i "s#python3 /opt/mdns/mdns_responder.py > /dev/null 2>&1 &#python3 $SCRIPT_DIR/mdns_responder.py > /dev/null 2>&1 #" "$SCRIPT_DIR/service/S55mdns-responder"

cp "$SCRIPT_DIR/service/S55mdns-responder" /etc/init.d/
chmod +x /etc/init.d/S55mdns-responder

/etc/init.d/S55mdns-responder start

echo "Service installed"
echo "Printer is now accessible on the local network at http://$HOSTNAME.local"