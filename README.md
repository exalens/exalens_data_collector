
## Overview
This document provides instructions for the installation, usage, and maintenance of the Retina DataCollector software.

## Table of Contents
1. [Starting DataCollector](#starting-datacollector)
2. [Stopping DataCollector](#stopping-datacollector)
3. [Updating DataCollector](#updating-datacollector)
4. [Uninstalling DataCollector](#uninstalling-datacollector)
5. [Updating Hostname](#updating-hostname)

## Starting DataCollector
To start the Retina DataCollector, follow these steps:
1. Download the DataCollector configuration from the user interface.
2. Extract the downloaded file using the command:
   ```
   ./retina-datacollector.sh --extract <download_dir>
   ```
   For example:
   ```
   ./retina-datacollector.sh --extract /home/dummyUser/Downloads/DummyDataCollector.tar.gz
   ```
   This extracts the files to `/opt/retinaDataCollector` and creates the directory if it does not exist.
3. Start DataCollector using:
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
