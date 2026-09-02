#!/bin/sh
set -e

SCRIPT_DIR=$(pwd)
cd "$SCRIPT_DIR"

read -p "Enter a hostname or press Enter for default(k2plus): " HOSTNAME
HOSTNAME="${HOSTNAME:-k2plus}"

python3 - "$SCRIPT_DIR/mdns_responder.py" "$HOSTNAME" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
hostname = sys.argv[2]

text = path.read_text()
new_text, count = re.subn(r'hostname\s*=\s*[\'"][^\'"]*[\'"]', f'hostname = "{hostname}"', text, count=1)
if count == 0:
    raise SystemExit("Could not find hostname assignment in mdns_responder.py")

path.write_text(new_text)
PY

cp "$SCRIPT_DIR/service/S55mdns-responder" /etc/init.d/S55mdns-responder

python3 - /etc/init.d/S55mdns-responder "$HOSTNAME" "$SCRIPT_DIR/mdns_responder.py" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
hostname = sys.argv[2]
responder_path = sys.argv[3]

text = path.read_text()

old1 = 'MDNS_HOSTNAME="${MDNS_HOSTNAME:-k2plus}" \\'
new1 = f'MDNS_HOSTNAME="{hostname}" \\'
if old1 in text:
    text = text.replace(old1, new1, 1)

old2 = 'python3 K2-mDNS/mdns_responder.py > /dev/null 2>&1 &'
new2 = f'python3 {responder_path} > /dev/null 2>&1 &'
if old2 in text:
    text = text.replace(old2, new2, 1)

path.write_text(text)
PY

chmod +x /etc/init.d/S55mdns-responder

/etc/init.d/S55mdns-responder start

echo "Printer is now accessible on the local network at http://$HOSTNAME.local"