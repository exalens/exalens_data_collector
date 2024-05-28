import sys
import os
import subprocess


def replay_pcap(pcap_filename):
    # Check the size of the pcap file
    file_size = os.path.getsize(pcap_filename)
    if file_size > 1 * 1024 * 1024 * 1024:  # 1GB in bytes
        print("Warning: The pcap file is larger than 1GB and will not be processed.")
        return  # Exit the function if the file is too large

    # Define the maximum bandwidth for replay
    max_bandwidth = "50Mbps"

    # Construct the tcpreplay command
    command = [
        "tcpreplay",
        "--intf1=dummy",  # Modify this to match your network interface
        f"--mbps={max_bandwidth}",
        "--stats=1",  # Update stats every second
        pcap_filename
    ]

    try:
        # Execute the tcpreplay command and handle the output for progress updates
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        print("Uploading PCAP file...")  # Initial message before replay begins
        while True:
            output = process.stdout.readline()
            if output == '' and process.poll() is not None:
                break
            if output:
                # Renaming output as required
                output = output.replace("Test start:", "PCAP upload started:")
                output = output.replace("Test complete:", "PCAP upload completed:")
                print(output.strip())  # Print each update provided by tcpreplay

        # Handling errors if there are any
        stderr = process.stderr.read()
        if stderr:
            print("Error during PCAP upload:", stderr)
        else:
            print("PCAP upload completed successfully.")  # Completion message
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 upload_pcap.py <filename.pcap>")
        sys.exit(1)

    pcap_filename = sys.argv[1]
    if not os.path.exists(pcap_filename):
        print("PCAP file does not exist.")
        sys.exit(1)

    replay_pcap(pcap_filename)
