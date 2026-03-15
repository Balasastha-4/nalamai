import socket
import os
import re

def get_lan_ip():
    """
    Robustly gets the current LAN IP by attempting to connect to an external address.
    """
    try:
        # We don't actually send data, just use the routing table to find the local IP used.
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        # Fallback to hostname if offline
        try:
            return socket.gethostbyname(socket.gethostname())
        except:
            return "127.0.0.1"

def update_flutter_files(new_ip):
    files_to_update = [
        "../lib/services/api_service.dart",
        "../lib/services/ai_service.dart"
    ]
    
    # regex to match IP:PORT patterns in the base URLs
    # Matches strings like 10.123.45.67 or 192.168.1.5
    ip_pattern = r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'

    for file_path in files_to_update:
        abs_path = os.path.join(os.path.dirname(__file__), file_path)
        if os.path.exists(abs_path):
            with open(abs_path, 'r') as f:
                content = f.read()
            
            # Replace all occurrences of IPs in the file
            new_content = re.sub(ip_pattern, new_ip, content)
            
            with open(abs_path, 'w') as f:
                f.write(new_content)
            print(f"Updated {file_path} with IP: {new_ip}")
        else:
            print(f"File not found: {abs_path}")

if __name__ == "__main__":
    ip = get_lan_ip()
    print(f"Detected TRUE LAN IP: {ip}")
    update_flutter_files(ip)
    print("Done! Please hot-restart your Flutter app.")
