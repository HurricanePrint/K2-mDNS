#!/bin/bash

cd "$(dirname "$0")"

read -p "Enter a hostname or press Enter for default(k2plus): " HOSTNAME
HOSTNAME="${HOSTNAME:-k2plus}"

python3 - "$HOSTNAME" <<'PY'
import sys
from pathlib import Path

hostname = sys.argv[1]
path = Path("mdns_responder.py")
text = path.read_text()

old = 'hostname = "k2plus"'
new = f'hostname = "{hostname}"'

if old in text:
    path.write_text(text.replace(old, new, 1))
else:
    old2 = "hostname = 'k2plus'"
    new2 = f"hostname = '{hostname}'"
    if old2 in text:
        path.write_text(text.replace(old2, new2, 1))
    else:
        raise SystemExit("Could not find hostname assignment in mdns_responder.py")
PY

cp service/S55mdns-responder /etc/init.d/
chmod +x /etc/init.d/S55mdns-responder

/etc/init.d/S55mdns-responder start
echo "Service is" `/etc/init.d/S55mdns-responder status`

echo "Printer is now accessible on the local network at http://$HOSTNAME.local"
