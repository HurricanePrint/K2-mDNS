import os
import signal
import socket
import struct
import time

STOP = False

def handle_stop(signum, frame):
    global STOP
    STOP = True

signal.signal(signal.SIGTERM, handle_stop)
signal.signal(signal.SIGINT, handle_stop)

def encode_dns_name(name):
    labels = name.strip().lower().split('.')
    out = bytearray()
    for label in labels:
        if not label:
            continue
        out.append(len(label))
        out.extend(label.encode('ascii'))
    out.append(0)
    return bytes(out)

def get_local_ip():
    """Executes ifconfig directly and extracts the live IP address string."""
    import subprocess
    
    try:
        # Run 'ifconfig wlan0' and capture the text output safely
        output = subprocess.check_output(['ifconfig', 'wlan0'], stderr=subprocess.STDOUT).decode('utf-8')
        
        # Look line by line through the ifconfig text block
        for line in output.split('\n'):
            if 'inet addr:' in line:
                # Splitting by 'inet addr:' and taking the right side, then splitting by spaces 
                # isolates the exact IP string perfectly (e.g., '10.0.0.215')
                ip = line.split('inet addr:')[1].split()[0].strip()
                if ip.startswith('10.') or ip.startswith('192.'):
                    return ip
    except Exception:
        pass
    
    return '127.0.0.1'


def run_mdns(hostname="k2plus"):
    global STOP
    port = 4408

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(('', 5353))

    mreq = struct.pack('4s4s', socket.inet_aton('224.0.0.251'), socket.inet_aton('0.0.0.0'))
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)

    print(f"Broadcasting dynamic mDNS info for {hostname}.local")

    # Track the active IP address in memory to prevent rebuilding packets unnecessarily
    current_ip = None
    packet = b''

    while not STOP:
        try:
            # Continuously query the interface state on every 10-second tick loop
            live_ip = get_local_ip()

            # If the IP changes (or turns up for the first time), dynamically rebuild the broadcast payload
            if live_ip != current_ip and live_ip != '127.0.0.1':
                print(f"IP state change detected! Updating mDNS payload: {live_ip}")
                current_ip = live_ip
                ip_bytes = socket.inet_aton(live_ip)

                hdr = struct.pack('!HHHHHH', 0, 0x8400, 0, 3, 0, 0)
                srv_name = encode_dns_name('_http._tcp.local')
                tgt_name = encode_dns_name(f'{hostname}.local')

                r1 = tgt_name + struct.pack('!HHIH', 1, 1, 120, 4) + ip_bytes
                srv_data = struct.pack('!HHH', 0, 0, port) + tgt_name
                r2 = srv_name + struct.pack('!HHIH', 33, 1, 120, len(srv_data)) + srv_data
                txt_data = b'\x07path=/'
                r3 = srv_name + struct.pack('!HHIH', 16, 1, 120, len(txt_data)) + txt_data

                packet = hdr + r1 + r2 + r3

            # Broadcast the packet if a valid configuration structure has been built
            if packet:
                sock.sendto(packet, ('224.0.0.251', 5353))
            
            time.sleep(10)
        except KeyboardInterrupt:
            break
        except Exception:
            pass

    sock.close()
    print("mDNS responder stopped")

if __name__ == '__main__':
    hostname = os.environ.get('MDNS_HOSTNAME', 'k2plus')
    run_mdns(hostname)
