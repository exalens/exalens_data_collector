import subprocess

def create_dummy_interface():
    interface_name = 'dummy'
    try:
        # Add the dummy interface
        subprocess.run(['sudo', 'ip', 'link', 'add', interface_name, 'type', 'dummy'], check=True)
        # Set the interface to promiscuous mode
        subprocess.run(['sudo', 'ip', 'link', 'set', interface_name, 'promisc', 'on'], check=True)
        # Disable ARP on the interface
        subprocess.run(['sudo', 'ip', 'link', 'set', interface_name, 'arp', 'off'], check=True)
        # Disable IPv6 on the interface
        # subprocess.run(['sudo', 'sysctl', '-w', f'net.ipv6.conf.{interface_name}.disable_ipv6=1'], check=True)
        # Disable multicast
        subprocess.run(['sudo', 'ip', 'link', 'set', interface_name, 'multicast', 'off'], check=True)
        # Disable broadcast
        subprocess.run(['sudo', 'ip', 'link', 'set', interface_name, 'broadcast', 'off'], check=True)
        # Bring the interface up
        subprocess.run(['sudo', 'ip', 'link', 'set', interface_name, 'up'], check=True)
        print(f"Dummy interface '{interface_name}' created.")
    except subprocess.CalledProcessError as e:
        print(f"Failed to create or configure the dummy interface: {str(e)}")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    create_dummy_interface()
