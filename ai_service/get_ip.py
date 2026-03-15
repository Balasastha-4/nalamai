import socket
hostname = socket.gethostname()
print(f"Hostname: {hostname}")
ips = socket.gethostbyname_ex(hostname)[2]
print(f"All IPs: {ips}")
for ip in ips:
    if ip.startswith("10.") or ip.startswith("172.") or ip.startswith("192."):
        print(f"Found LAN IP: {ip}")
