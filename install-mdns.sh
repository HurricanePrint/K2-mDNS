#!/bin/sh
set -e

SCRIPT_DIR=$(pwd)
cd "$SCRIPT_DIR"

read -p "Enter a hostname or press Enter for default(k2plus): " HOSTNAME
HOSTNAME="${HOSTNAME:-k2plus}"

# Replace hostname in the responder
python3 - "$SCRIPT_DIR/mdns_responder.py" "$HOSTNAME" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
hostname = sys.argv[2]

text = path.read_text()
old = 'hostname = "k2plus"'
new = f'hostname = "{hostname}"'

if old in text:
    text = text.replace(old, new, 1)
else:
    old = "hostname = 'k2plus'"
    new = f"hostname = '{hostname}'"
    if old in text:
        text = text.replace(old, new, 1)
    else:
        raise SystemExit("Could not find hostname assignment in mdns_responder.py")

path.write_text(text)
PY

# Replace the launch path in the service file
python3 - "$SCRIPT_DIR/service/S55mdns-responder" "$SCRIPT_DIR/mdns_responder.py" <<'PY'
import sys
from pathlib import Path

service_path = Path(sys.argv[1])
responder_path = sys.argv[2]

text = service_path.read_text()
old = "python3 mdns_responder.py > /dev/null 2>&1 &"
new = f"python3 {responder_path} > /dev/null 2>&1 &"

if old in text:
    text = text.replace(old, new, 1)
else:
    raise SystemExit("Could not find mdns_responder.py launch line in service file")

service_path.write_text(text)
PY

cp "$SCRIPT_DIR/service/S55mdns-responder" /etc/init.d/
chmod +x /etc/init.d/S55mdns-responder

/etc/init.d/S55mdns-responder start

echo "Service installed"
echo "Printer is now accessible on the local network at http://$HOSTNAME.local"