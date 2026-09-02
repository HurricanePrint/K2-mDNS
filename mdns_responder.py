import socket
import struct
import time

def run_mdns():
    hostname = "k2plus"
    port = 4408
    
    # Auto-detect printer IP
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 1))
        local_ip = s.getsockname()[0]
    except Exception:
        local_ip = '127.0.0.1'
    finally:
        s.close()

    ip_bytes = socket.inet_aton(local_ip)
    
    # Constructing a complete DNS Answer packet with A, SRV, and TXT records
    # This matches upstream standards so Windows recognizes it as a true web service endpoint
    hdr = struct.pack('!HHHHHH', 0, 0x8400, 0, 3, 0, 0) # 3 Answer RRs
    
    # 1. Encode Name Query (_http._tcp.local)
    srv_name = b'\x05_http\x04_tcp\x05local\x00'
    tgt_name = b'\x06k2plus\x05local\x00'
    
    # Record 1: Type A (IP Address mapping)
    r1 = tgt_name + struct.pack('!HHIH', 1, 1, 120, 4) + ip_bytes
    
    # Record 2: Type SRV (Port mapping for Windows background sockets)
    # Priority (0), Weight (0), Port (4408), Target (k2plus.local)
    srv_data = struct.pack('!HHH', 0, 0, port) + tgt_name
    r2 = srv_name + struct.pack('!HHIH', 33, 1, 120, len(srv_data)) + srv_data
    
    # Record 3: Type TXT (Path definition)
    txt_data = b'\x07path=/'
    r3 = srv_name + struct.pack('!HHIH', 16, 1, 120, len(txt_data)) + txt_data
    
    packet = hdr + r1 + r2 + r3

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(('', 5353))

    mreq = struct.pack('4s4s', socket.inet_aton('224.0.0.251'), socket.inet_aton('0.0.0.0'))
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)

    print(f"Broadcasting comprehensive mDNS profile for {hostname}.local")
    while True:
        try:
            sock.sendto(packet, ('224.0.0.251', 5353))
            time.sleep(10)
        except KeyboardInterrupt:
            break
        except Exception:
            pass

if __name__ == '__main__':
    run_mdns()