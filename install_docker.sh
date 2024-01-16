# 2/ Install docker
IS_DOCKER_INSTALLED="true"
if ! (docker --version | grep -q "Docker version" ) ; then
    IS_DOCKER_INSTALLED="false"
    echo "Could not find docker installation, it will be installed"
    sudo apt-get update -y
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    DEBIAN_FRONTEND="noninteractive" sudo apt install -y tzdata
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# 3/ Install docker-compose
if ! (docker-compose --version | grep -q "version v" ) ; then
    echo "Could not find docker-compose, it will be installed"
    # install prereq
    sudo apt install jq -y
    # uninstall remaining
    sudo apt-get remove -y docker-compose >/dev/null 2>&1 || true
    sudo rm /usr/local/bin/docker-compose >/dev/null 2>&1 || true
    pip3 uninstall docker-compose >/dev/null 2>&1 || true
    # install it
    VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)
    DESTINATION=/usr/local/bin/docker-compose
    sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
    sudo chmod +x $DESTINATION
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose >/dev/null 2>&1 || true
fi

# 4/ Start docker daemon (only in container)
if [[ $IS_DOCKER_INSTALLED == "false" ]]; then
    (sudo dockerd &) &> /dev/null
fi

# 5/ add current user to privileged group (effective only after reboot)
# docker-compose and docker will be able to start without sudo
if [[ $IS_DOCKER_INSTALLED == "false" ]]; then
    sudo groupadd docker | true
    sudo usermod -aG docker $USER
fi

# 6/ verify group present in groups
if groups | grep -q 'docker'; then
    :
    #echo "docker exists in groups"
else
    echo "docker does not exists in groups"
    echo "Please restart your machine and launch the script again."
    read -r -p "Do you want to restart your machine now? [y/N] " response
      case "$response" in
          [yY][eE][sS]|[yY])
              sudo reboot
              ;;
          *)
              echo "Until your machine is restarted, you can only access docker services with sudo"
              ;;
      esac
    exit 1;
fi
