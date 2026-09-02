#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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

python3 - "$SERVICE_SRC" "$SCRIPT_DIR/mdns_responder.py" <<'PY'
import sys
from pathlib import Path

service_path = Path(sys.argv[1])
responder_path = sys.argv[2]

text = service_path.read_text()

old = "python3 /opt/mdns/mdns_responder.py > /dev/null 2>&1 &"
new = f"python3 {responder_path} > /dev/null 2>&1 &"

if old in text:
    service_path.write_text(text.replace(old, new, 1))
else:
    raise SystemExit("Could not find mdns_responder.py launch line in service file")
PY

python3 - "$SCRIPT_DIR/service/S55mdns-responder" "$SCRIPT_DIR/mdns_responder.py" <<'PY'
import sys
from pathlib import Path

service_path = Path(sys.argv[1])
responder_path = sys.argv[2]

text = service_path.read_text()
old = "python3 /opt/mdns/mdns_responder.py > /dev/null 2>&1 &"
new = f"python3 {responder_path} > /dev/null 2>&1 &"

if old in text:
    service_path.write_text(text.replace(old, new, 1))
else:
    raise SystemExit("Could not find mdns_responder.py launch line in service file")
PY

cp "$SCRIPT_DIR/service/S55mdns-responder" /etc/init.d/
chmod +x /etc/init.d/S55mdns-responder

/etc/init.d/S55mdns-responder start
echo "Service is" `/etc/init.d/S55mdns-responder status`

echo "Printer is now accessible on the local network at http://$HOSTNAME.local"
