import csv
import subprocess
import argparse
import os
import re

def load_whitelist(file_path, debug):
    whitelist = {}
    if os.path.exists(file_path):
        with open(file_path, mode='r', newline='') as file:
            reader = csv.reader(file)
            for row in reader:
                if len(row) == 2:
                    whitelist[row[0].lower()] = row[1]
    if debug:
        print(f"Loaded whitelist: {whitelist}")
    return whitelist

def run_nmap_scan(network, debug):
    command = ["nmap", "-sn", "-PR", "--host-timeout", "5s", "--min-parallelism", "10", network]
    if debug:
        print(f"Running command: {' '.join(command)}")
    result = subprocess.run(command, capture_output=True, text=True)
    if debug:
        print(f"Nmap output:\n{result.stdout}")
    return result.stdout

def parse_nmap_output(output, debug):
    devices = []
    current_ip = None
    current_mac = None
    
    for line in output.split('\n'):
        ip_match = re.search(r'Nmap scan report for ([0-9\.]+)', line)
        mac_match = re.search(r'MAC Address: ([0-9A-Fa-f:]+)', line)
        
        if ip_match:
            current_ip = ip_match.group(1)
        elif mac_match:
            current_mac = mac_match.group(1).lower()
            if current_ip:
                devices.append((current_mac, current_ip))
                if debug:
                    print(f"Found device: MAC={current_mac}, IP={current_ip}")
                current_ip = None
                current_mac = None
    
    return devices

def save_connected_devices(devices, whitelist, output_file, debug):
    output_dir = os.path.dirname(output_file)
    os.makedirs(output_dir, exist_ok=True)
    
    if debug:
        print(f"Saving results to {output_file}")
    with open(output_file, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(["mac_address", "name", "ip_address"])
        for mac, ip in devices:
            name = whitelist.get(mac, "Unknown")
            writer.writerow([mac, name, ip])
            if debug:
                print(f"Saved: {mac}, {name}, {ip}")

def main():
    parser = argparse.ArgumentParser(description="ARP scan a network and match against a whitelist.")
    parser.add_argument("--network", default="192.168.3.1/24", help="Network to scan (default: 192.168.3.1/24)")
    parser.add_argument("--whitelist", default="../etc/macs.csv", help="Path to whitelist CSV file (default: ../etc/macs.csv)")
    parser.add_argument("--output", default="../var/log/connected.csv", help="Output CSV file (default: ../var/log/connected.csv)")
    parser.add_argument("--debug", action="store_true", help="Enable debug mode for verbose output")
    
    args = parser.parse_args()
    
    if args.debug:
        print(f"Arguments: {args}")
    
    whitelist = load_whitelist(args.whitelist, args.debug)
    nmap_output = run_nmap_scan(args.network, args.debug)
    devices = parse_nmap_output(nmap_output, args.debug)
    save_connected_devices(devices, whitelist, args.output, args.debug)
    
    print(f"Scan complete. Results saved to {args.output}")
    
if __name__ == "__main__":
    main()
