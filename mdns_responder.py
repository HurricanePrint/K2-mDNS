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
    """Reads network sockets offline to discover a valid 10.x or 192.x address."""
    try:
        # Fetch all IP network interfaces bound to the machine architecture
        interfaces = socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET)
        for s_addr in interfaces:
            ip = s_addr[4][0]
            if ip.startswith('10.') or ip.startswith('192.'):
                return ip
    except Exception:
        pass

    # Fallback method checking local socket routing endpoints safely
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # Check standard routing tables without establishing an external data stream
        for target in ['10.255.255.255', '192.168.255.255']:
            try:
                s.connect((target, 1))
                ip = s.getsockname()[0]
                if ip.startswith('10.') or ip.startswith('192.'):
                    return ip
            except Exception:
                continue
    except Exception:
        pass
    finally:
        s.close()
        
    return '127.0.0.1'

def run_mdns(hostname="k2plus"):
    global STOP
    port = 4408

    # Use the robust offline detection method
    local_ip = get_local_ip()
    print(f"Detected offline IP for mDNS advertisement: {local_ip}")

    ip_bytes = socket.inet_aton(local_ip)

    hdr = struct.pack('!HHHHHH', 0, 0x8400, 0, 3, 0, 0)

    srv_name = encode_dns_name('_http._tcp.local')
    tgt_name = encode_dns_name(f'{hostname}.local')

    r1 = tgt_name + struct.pack('!HHIH', 1, 1, 120, 4) + ip_bytes

    srv_data = struct.pack('!HHH', 0, 0, port) + tgt_name
    r2 = srv_name + struct.pack('!HHIH', 33, 1, 120, len(srv_data)) + srv_data

    txt_data = b'\x07path=/'
    r3 = srv_name + struct.pack('!HHIH', 16, 1, 120, len(txt_data)) + txt_data

    packet = hdr + r1 + r2 + r3

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(('', 5353))

    mreq = struct.pack('4s4s', socket.inet_aton('224.0.0.251'), socket.inet_aton('0.0.0.0'))
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)

    print(f"Broadcasting mDNS info for {hostname}.local")

    while not STOP:
        try:
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
