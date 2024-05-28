import argparse
import subprocess
import sys
import os

def run_command(command):
    try:
        subprocess.run(command, check=True, shell=True)
        #print(f"Successfully executed: {' '.join(command)}")
    except subprocess.CalledProcessError as e:
        print(f"Error executing {' '.join(command)}: {e}", file=sys.stderr)
        raise Exception(f"Command failed: {command}")

def ensure_directory():
    directories = {
        "/etc/iptables": ["rules.v4", "rules.v6"],
        "/etc/ebtables": ["rules-save"]
    }
    for path, files in directories.items():
        if not os.path.exists(path):
            os.makedirs(path)
        for file in files:
            if not os.path.exists(os.path.join(path, file)):
                open(os.path.join(path, file), 'a').close()

def set_monitoring(interface):
    try:
        ensure_directory()
        # Enable promiscuous mode
        run_command(f"ip link set {interface} promisc on")
        # Disable ARP
        run_command(f"ip link set {interface} arp off")
        # Block all inbound and outbound IPv4 and IPv6 connections via iptables and ip6tables
        run_command(f"iptables -I INPUT -i {interface} -j DROP")
        run_command(f"iptables -I OUTPUT -o {interface} -j DROP")
        run_command(f"ip6tables -I INPUT -i {interface} -j DROP")
        run_command(f"ip6tables -I OUTPUT -o {interface} -j DROP")
        # Save iptables and ip6tables rules
        run_command("iptables-save > /etc/iptables/rules.v4")
        run_command("ip6tables-save > /etc/iptables/rules.v6")
        # Block outbound frames using ebtables
        run_command(f"ebtables -A OUTPUT -o {interface} -j DROP")
        run_command("ebtables-save > /etc/ebtables/rules-save")
        print(f"Monitoring configuration successfully set for {interface}")
    except Exception as e:
        print(f"Failed to set monitoring configuration for {interface}: {e}")

def remove_monitoring(interface):
    try:
        ensure_directory()
        # Disable promiscuous mode
        run_command(f"ip link set {interface} promisc off")
        # Enable ARP
        run_command(f"ip link set {interface} arp on")
        # Remove iptables and ip6tables rules
        run_command(f"iptables -D INPUT -i {interface} -j DROP")
        run_command(f"iptables -D OUTPUT -o {interface} -j DROP")
        run_command(f"ip6tables -D INPUT -i {interface} -j DROP")
        run_command(f"ip6tables -D OUTPUT -o {interface} -j DROP")
        # Save iptables and ip6tables rules
        run_command("iptables-save > /etc/iptables/rules.v4")
        run_command("ip6tables-save > /etc/iptables/rules.v6")
        # Remove ebtables rules
        run_command(f"ebtables -D OUTPUT -o {interface} -j DROP")
        run_command("ebtables-save > /etc/ebtables/rules-save")
        print(f"Monitoring configuration successfully removed for {interface}")
    except Exception as e:
        print(f"Failed to remove monitoring configuration for {interface}: {e}")

def main():
    parser = argparse.ArgumentParser(description='Set or remove monitoring configuration for a network interface.')
    parser.add_argument('interface', type=str, help='The network interface to configure')
    parser.add_argument('--set', action='store_true', help='Set the monitoring configuration')
    parser.add_argument('--remove', action='store_true', help='Remove the monitoring configuration')

    args = parser.parse_args()

    if args.set:
        set_monitoring(args.interface)
    elif args.remove:
        remove_monitoring(args.interface)
    else:
        print("Please specify --set or --remove")
        sys.exit(1)

if __name__ == "__main__":
    main()
