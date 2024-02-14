# DataCollector Management Script

This document provides detailed instructions for the installation, usage, and maintenance of the DataCollector, a tool for managing data collection environments.

## Table of Contents

1. [Starting DataCollector](#starting-datacollector)
2. [Stopping DataCollector](#stopping-datacollector)
3. [Updating DataCollector](#updating-datacollector)
4. [Uninstalling DataCollector](#uninstalling-datacollector)
5. [Updating Hostname](#updating-hostname)
6. [Setting Network Interface to Promiscuous Mode](#setting-network-interface-to-promiscuous-mode)

## Starting DataCollector

To start the Retina DataCollector using the CLI for downloading and extracting configurations, follow these steps:

1. **Download and Extract Configuration:**
   To download and extract the DataCollector configuration using CLI, use the command:
   ```
   ./retina-datacollector.sh --download
   ```
   During this process, you will be prompted to enter the following details:
   - Cortex hostname
   - Data collector name which is registered
   - Choose the data collector you want to use
   - Username
   - Password (input is hidden for security)
   After downloading, the script automatically extracts the configuration.

2. **Start DataCollector:**
   To start the DataCollector:
   ```
   ./retina-datacollector.sh --start
   ```

## Stopping DataCollector

To stop the DataCollector:
```
./retina-datacollector.sh --stop
```

## Updating DataCollector

To update the DataCollector:
```
./retina-datacollector.sh --update
```

## Uninstalling DataCollector

To uninstall the DataCollector:
```
./retina-datacollector.sh --uninstall
```

## Updating Hostname

To update the hostname for the DataCollector:
```
./retina-datacollector.sh --update-hostname <cortex-hostname>
```
Replace `<cortex-hostname>` with your actual hostname.

## Setting Network Interface to Promiscuous Mode

To set a network interface to promiscuous mode:
```
./retina-datacollector.sh --set_promisc
```
This command lists all available network interfaces for selection.
