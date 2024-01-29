
## Overview
This document provides instructions for the installation, usage, and maintenance of the DataCollector.

## Table of Contents
1. [Starting DataCollector](#starting-datacollector)
2. [Stopping DataCollector](#stopping-datacollector)
3. [Updating DataCollector](#updating-datacollector)
4. [Uninstalling DataCollector](#uninstalling-datacollector)
5. [Updating Hostname](#updating-hostname)
6. [Setting network interface to promiscuous mode](#promiscuous-mode)

## Starting DataCollector
To start the Retina DataCollector, follow these steps:
There are two ways to setup the DataCollector, one using the GUI to download (1) and extract (2) the configuration and using the CLI to download and extract (3).
1. Download the DataCollector configuration from the user interface.
   If you are planning on running the probe in a different machine from where you have downloaded the configuration (say a virutal machine) please use the following scp commad to move the downloaded configuration
   ```
   scp /path/to/localfile.tar.gz username@remote_IP:/remote/directory
   ```
2. Extract the downloaded file using the command:
   ```
   ./retina-datacollector.sh --extract <download_dir>
   ```
   For example:
   ```
   ./retina-datacollector.sh --extract /home/dummyUser/Downloads/DummyDataCollector.tar.gz
   ```
   This extracts the files to `/opt/retinaDataCollector` and creates the directory if it does not exist.
   The argument <download_dir> is optional, provided the downloaded configuration (.tar.gz) file is present in the same directory as the retina-datacollector.sh script.
4. CLI options (Download and Extract):
  To download and extract the data collector configuration using CLI use the command.
   ```
   ./retina-datacollector.sh --download>
   ```
   Followed by which you'll be prompted to input the following
   ```
   >>Enter the cortex hostname: <hotname>
   >>Enter the data collector name: <data-collector-name>
   >>Enter the Username: <User>
   >>Enter the Password: <Pass
   ```
   Thereafter start the DataCollector as mentioned in (4)
   
5. Start DataCollector using:
   ```
   ./retina-datacollector.sh --start
   ```

## Stopping DataCollector
To stop the Retina DataCollector, use the command:
```
./retina-datacollector.sh --stop
```

## Updating DataCollector
To update the Retina DataCollector, use the command:
```
./retina-datacollector.sh --update
```

## Uninstalling DataCollector
To uninstall the Retina DataCollector, use the command:
```
./retina-datacollector.sh --uninstall
```

## Updating Hostname
To update the hostname configuration for Retina DataCollector, use the command:
```
./retina-datacollector.sh --update-hostname <cortex-hostname>
```
Replace `<cortex-hostname>` with your actual hostname.

## Setting network interface to promiscuous mode
To set a network interface to promiscuous mode you can use the following command.
```
./retina-datacollector.sh --set_promisc
```
This will list all available network interfaces. 

