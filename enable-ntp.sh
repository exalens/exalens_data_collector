!/bin/bash

# Check if systemd-timesyncd service is enabled
systemd_active=$(systemctl is-enabled systemd-timesyncd)
if [ "$systemd_active" != "enabled" ]; then
    echo "systemd-timesyncd is not enabled. Enabling now..."
    sudo systemctl enable systemd-timesyncd
    sudo systemctl start systemd-timesyncd
else
    echo "systemd-timesyncd is already enabled."
fi


# Check if systemd-timesyncd service is active
systemd_running=$(systemctl is-active systemd-timesyncd)
if [ "$systemd_running" != "active" ]; then
    echo "systemd-timesyncd is not active. Starting now..."
    sudo systemctl start systemd-timesyncd
else
    echo "systemd-timesyncd is already active."
fi

# Check if the system time is synchronized with an NTP server
ntp_sync_status=$(timedatectl show --property=NTP --value)

if [ "$ntp_sync_status" = "yes" ]; then
    echo "System time is synchronized with an NTP server."
else
    echo "System time is not synchronized with an NTP server. Attempting to enable NTP..."
    # Enable and start systemd-timesyncd service (this will enable NTP synchronization)
    sudo apt-get update
    sudo apt-get install chrony
    sudo systemctl enable chronyd
    sudo systemctl start chronyd

    timedatectl set-ntp true
    echo "NTP service has been enabled and will attempt synchronization."
fi
