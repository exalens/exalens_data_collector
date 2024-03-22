#!/bin/bash



PRIMARY=""
BASE_DIR=~/.exalens/retinaProbe
TAG="latest"


set_tag() {
  TAG=$1
  if [ -z "$TAG" ]; then
#    echo "Please provide the tag for images."
#    read TAG
    TAG="latest"
  fi

}


download_cfg() {
    read -p "Enter the cortex hostname: " HOSTNAME
    read -p "Enter the data collector name: " PROBE_NAME
    read -p "Enter the Username: " USER
    read -s -p "Enter the Password: " PASS

    # The URL and output file name could be hardcoded or made dynamic as well
    local url="https://"$HOSTNAME"/api/probe/download_cfg"
    local output_file=$BASE_DIR"/"$PROBE_NAME".tar.gz"
    sudo mkdir -p $BASE_DIR
    sudo chmod 777 $BASE_DIR
    # Constructing and executing the curl command
    curl -k -X GET "$url" -H "User: $USER" -H "Pass: $PASS" -H "name: $PROBE_NAME" --output "$output_file"

    if [ ! -f "$output_file" ]; then
        echo "Download failed!"
        return 1
    fi

    # Determine the type of the file
    local file_type=$(file --mime-type -b "$output_file")
    temp="${output_file%/*}/error.json"
    rm -f $temp
    if [ "$file_type" = "application/json" ]; then
        echo "Something went wrong. Kindly check the error("$temp")."
        mv "$output_file" $temp
    elif [[ $file_type == "application/gzip" ]]; then
#        echo "Downloaded configuration saved to $output_file"
        echo "Download Complete."
        extract $output_file
    elif [[ $file_type == "text/plain" ]]; then
        echo | cat $output_file
        rm -f $output_file
    else
        echo "Somthing went wrong."
    fi
}


extract(){
  DOWNLOAD=$1
  if [[ -z $DOWNLOAD ]]; then
    echo "Argument Missing <Download Path>"
    exit 1
  fi
  if [ ! -d $BASE_DIR ]; then
    # Create the directory
    sudo mkdir -p $BASE_DIR
    sudo chmod 777 $BASE_DIR
  fi
  (cd $BASE_DIR && sudo tar -xzvf $DOWNLOAD --strip-components=0 > /dev/null)
  echo "Extraction complete."
}


extract_latest_tar_gz() {
    # Define the directory to search in
    local directory=$1

    # Check if the directory is provided
    if [ -z "$directory" ]; then
        echo "Please specify a directory."
        return 1
    fi

    # Check if the directory exists
    if [ -d "$directory" ]; then
        # Find the latest .tar.gz file
        local latest_file=$(find "$directory" -name '*.tar.gz' -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)

        # Check if any .tar.gz files were found
        if [ -z "$latest_file" ]; then
            echo "No .tar.gz files found in $directory"
            return 1
        fi
    else
      latest_file=$directory
    fi

    echo "Extracting $latest_file..."
    extract $latest_file
}


set_promiscuous_mode() {

    echo "Available network interfaces:"
    interfaces=($(ip -o link show | awk -F': ' '{print $2}' | awk -F'@' '{print $1}'))

    select interface in "${interfaces[@]}"; do
        if [ -n "$interface" ]; then
            echo "You have selected the interface: $interface"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    if [ -z "$interface" ]; then
        echo "No interface selected to set to promiscuous mode."
        return 1
    fi

    # Set the network interface to promiscuous mode
    sudo ip link set "$interface" promisc on
    if [ $? -eq 0 ]; then
        echo "Successfully set $interface to promiscuous mode."
    else
        echo "Failed to set $interface to promiscuous mode."
    fi
}


# Function to pull an image if not present
pull_if_not_exists() {
    if ! docker image inspect $1 > /dev/null 2>&1; then
        echo "Image $1 not found. Pulling..."
        docker pull $1
    fi
}

pull_images() {
    echo "Pulling all images with tag $TAG..."

    # Pull all the containers
    docker pull exalens/community_probe:$TAG
    docker pull exalens/community_zeek:$TAG
}

start_services() {
    echo "Starting services..."
    clear_progress_file

    # Function to stop and remove a container if it is running
    stop_and_remove_if_running() {
        if docker ps --format '{{.Names}}' | grep -q $1; then
            docker stop $1 > /dev/null
            docker rm $1 > /dev/null
        fi
    }

    # Check and stop/remove containers if they are already running
    stop_and_remove_if_running probe
    stop_and_remove_if_running probe_ctrl
    stop_and_remove_if_running zeek

    # Check if the 'exalens' network exists
    if ! docker network ls | grep -q "exalens"; then
        docker network create exalens
    fi

    # Pull necessary images if not exists
    pull_if_not_exists exalens/community_probe:$TAG
    pull_if_not_exists exalens/community_zeek:$TAG

    # Start the containers
    docker run -d \
      --name probe_ctrl \
      --restart always \
      --volume ~/.docker:/root/.docker \
      --volume $BASE_DIR:/opt/retinaProbe \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      --network host \
      --workdir /home/exalens/retinaProbeCtrl \
      --entrypoint python3.10 \
      exalens/community_probe:$TAG probeCtrl.py > /dev/null


#    progress
    echo "Services started."
}


stop_services() {
    echo "Stopping and removing services..."

    # Function to stop and remove a container only if it is running
    stop_and_remove_if_running() {
        if docker ps --format '{{.Names}}' | grep -q $1; then
            docker stop $1 > /dev/null
            docker rm $1 > /dev/null
        fi
    }

    # Stop and remove each container only if it is running
    stop_and_remove_if_running probe
    stop_and_remove_if_running probe_ctrl
    stop_and_remove_if_running zeek

    echo "stop completed."
}


uninstall(){
    echo "Removing installation"
    remove_containers_images_saved_data
    echo "Uninstallation complete."
}

remove_containers_images_saved_data(){
      # Stop all running services
    echo "Stopping all running services..."
    stop_services

    echo "Removing all images"
    docker rmi $(docker images -q) > /dev/null

    # Delete the .exalens folder
    echo "Deleting saved data and configurations..."
    sudo rm -rf $BASE_DIR

}

update_images() {
    echo "Updating all images..."

    # Stop all running services
    echo "Stopping all running services..."
    stop_services

    # Pull all Docker images
    echo "Pulling Docker images with tag $TAG..."
    pull_images

    # Restart the services
    echo "Restarting services..."
    start_services

    echo "Update completed."
}


file_path="$HOME/.exalens/retinaProbe/log/boot.log"
clear_progress_file(){
  # Delete the file if it exists
  if [ -f "$file_path" ]; then
      rm -f "$file_path"
  fi

}

progress(){

  extract_percentage() {
      echo "$1" | grep -oP '(?<=:)\d+(?=%)'
  }

  prev_percent="0"

  while [ ! -f "$file_path" ]; do
      echo -ne "\r${spinner:$i:1} Current progress: $prev_percent% \r"
      sleep 0.1
  done



  tail -f "$file_path" | while read line; do
      percent=$(extract_percentage "$line")
      if [ ! -z "$percent" ] && [ "$percent" != "$prev_percent" ]; then
          echo -ne "Current progress: $percent% \r"
          prev_percent=$percent
      fi

      if [[ "$percent" =~ ^[0-9]+$ ]] && [ "$percent" -eq 100 ]; then
          echo -ne "\nStartup completed.\n"
          break
      fi
  done

}

stop_and_remove_if_running() {
    if docker ps --format '{{.Names}}' | grep -q $1; then
        docker stop $1 > /dev/null
        docker rm $1 > /dev/null
    fi
}

update_probe_hostname(){
  docker exec probe_ctrl python3.10 updateHostname.py $1
}




BASE_DIR_UPDATE=0
DOWNLOAD_LOCATION_UPDATE=0
DOWNLOAD_LOC=$BASE_DIR
resolve_arguments(){
  for arg in "$@"

  do
      if [[ $BASE_DIR_UPDATE -eq 1 ]]; then
        BASE_DIR_UPDATE=2
        BASE_DIR=$arg
      fi

      if [[ $DOWNLOAD_LOCATION_UPDATE -eq 1 ]]; then
        DOWNLOAD_LOCATION_UPDATE=2
        DOWNLOAD_LOC=$arg
      fi

      case $arg in
#          -b|--base-dir)
#          BASE_DIR_UPDATE=1
#          shift # Remove argument name from processing
#          shift # Remove argument value from processing
#          ;;
          --extract)
            PRIMARY=--extract
            DOWNLOAD_LOCATION_UPDATE=1
            ;;
          --start)
            PRIMARY=--start
            ;;
          --stop)
            PRIMARY=--stop
            ;;
          --update)
            PRIMARY=--update
            ;;
          --update-hostname)
            PRIMARY=--update-hostname
            ;;
          --uninstall)
            PRIMARY=--uninstall
            ;;
          --download)
            PRIMARY=--download
            ;;
          --set_promisc)
            PRIMARY=--set_promisc
            ;;
      esac

  done
}

resolve_arguments $@

case $PRIMARY in
    --extract)
        extract_latest_tar_gz $DOWNLOAD_LOC
        ;;
    --start)
        set_tag $2
        start_services
        ;;
    --stop)
        stop_services
        ;;
    --update)
        set_tag $2
        update_images
        ;;
    --update-hostname)
        update_probe_hostname "$2"
        ;;
    --uninstall)
        uninstall
        ;;
    --download)
        download_cfg
        ;;
    --set_promisc)
        # Main script logic
        set_promiscuous_mode
        ;;
    *)
        echo "Usage: $PRIMARY --extract <download_dir> --start <tag>| --stop | --update <tag>| --update-hostname {hostname} | --uninstall | --download | --set_promisc"
        exit 1
esac
