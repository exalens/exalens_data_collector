#!/bin/bash



PRIMARY=""
BASE_DIR=/opt/retinaProbe

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
}

# Function to pull an image if not present
pull_if_not_exists() {
    if ! docker image inspect $1 > /dev/null 2>&1; then
        echo "Image $1 not found. Pulling..."
        docker pull $1
    fi
}

pull_images() {
    echo "Pulling all images..."

    # Pull all the containers
    docker pull exalens/community_probe:latest
    docker pull exalens/community_zeek:latest
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
    pull_if_not_exists exalens/community_probe:latest
    pull_if_not_exists exalens/community_zeek:latest

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
      exalens/community_probe:latest probeCtrl.py > /dev/null


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
    echo "Pulling latest Docker images..."
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
DOWNLOAD_LOC=""
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
      esac

  done
}

resolve_arguments $@

case $PRIMARY in
    --extract)
        extract $DOWNLOAD_LOC
        ;;
    --start)
        start_services
        ;;
    --stop)
        stop_services
        ;;
    --update)
        update_images
        ;;
    --update-hostname)
        update_probe_hostname "$2"
        ;;
    --uninstall)
        uninstall
        ;;
    *)
        echo "Usage: $PRIMARY --extract {download_dir} --start | --stop | --update | --update-hostname {hostname} | --uninstall "
        exit 1
esac
