#!/bin/sh
set -e

SCRIPT_DIR=$(pwd)
cd "$SCRIPT_DIR"
SERVICE_FILE="./service/K2-mDNS"
RESPONDER_PATH="$SCRIPT_DIR/mdns_responder.py"

read -p "Enter a hostname or press Enter for default(k2plus): " HOSTNAME
HOSTNAME="${HOSTNAME:-k2plus}"

python3 - "$RESPONDER_PATH" "$HOSTNAME" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
hostname = sys.argv[2]

text = path.read_text()
new_text, count = re.subn(
    r'hostname\s*=\s*[\'"][^\'"]*[\'"]',
    f'hostname = "{hostname}"',
    text,
    count=1,
)

if count == 0:
    raise SystemExit("Could not find hostname assignment")

path.write_text(new_text)
PY

python3 - "$SERVICE_FILE" "$RESPONDER_PATH" <<'PY'
import re
import shlex
import sys
from pathlib import Path

service_file = Path(sys.argv[1])
responder_path = sys.argv[2]

text = service_file.read_text()
replacement = f"MDNSSCRIPT={shlex.quote(responder_path)}"

new_text, count = re.subn(
    r'^\s*MDNSSCRIPT=.*$',
    replacement,
    text,
    count=1,
    flags=re.MULTILINE,
)

if count == 0:
    raise SystemExit("Could not find MDNSSCRIPT in the service file")

service_file.write_text(new_text)
PY

cp "$SERVICE_FILE" /etc/init.d/
chmod +x /etc/init.d/K2-mDNS
/etc/init.d/K2-mDNS enable
/etc/init.d/K2-mDNS start
echo "Service is" `/etc/init.d/K2-mDNS status`
echo "Printer is now accessible on the local network at http://$HOSTNAME.local"