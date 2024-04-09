#!/bin/bash

# User and home directory
USER_NAME=${SUDO_USER:-$(whoami)}
USER_HOME=$(getent passwd ${USER_NAME} | cut -d: -f6)

# Configuration variables
CONTAINER_NAME="sentinel-dvpn-node"
OUTPUT_DEBUG=true
FIREWALL="ufw"
NODE_MONIKER=""
NODE_TYPE="wireguard"
NODE_IP="0.0.0.0"
NODE_PORT=16567
NODE_LOCATION="datacenter"
WIREGUARD_PORT=16568
V2RAY_PORT=16568
CHAIN_ID="sentinelhub-2"
WALLET_NAME="operator"

# Fixed values
BACKEND="test"
RPC_ADDRESSES="https://rpc.sentinel.co:443,https://rpc.sentinel.quokkastake.io:443,https://rpc.trinityvalidator.com:443"
DATACENTER_GIGABYTE_PRICES="52573ibc/31FEE1A2A9F9C01113F90BD0BBCCE8FD6BBB8585FAF109A2101827DD1D5B95B8,9204ibc/A8C2D23A1E6F95DA4E48BA349667E322BD7A6C996D8A4AAE8BA72E190F3D1477,1180852ibc/B1C0DDB14F25279A2026BC8794E12B259F8BDA546A3C5132CCAEE4431CE36783,122740ibc/ED07A3391A112B175915CD8FAF43A2DA8E4790EDE12566649D0C2F97716B8518,15342624udvpn"
DATACENTER_HOURLY_PRICES="18480ibc/31FEE1A2A9F9C01113F90BD0BBCCE8FD6BBB8585FAF109A2101827DD1D5B95B8,770ibc/A8C2D23A1E6F95DA4E48BA349667E322BD7A6C996D8A4AAE8BA72E190F3D1477,1871892ibc/B1C0DDB14F25279A2026BC8794E12B259F8BDA546A3C5132CCAEE4431CE36783,18897ibc/ED07A3391A112B175915CD8FAF43A2DA8E4790EDE12566649D0C2F97716B8518,4160000udvpn"
RESIDENTIAL_GIGABYTE_PRICES="52573ibc/31FEE1A2A9F9C01113F90BD0BBCCE8FD6BBB8585FAF109A2101827DD1D5B95B8,9204ibc/A8C2D23A1E6F95DA4E48BA349667E322BD7A6C996D8A4AAE8BA72E190F3D1477,1180852ibc/B1C0DDB14F25279A2026BC8794E12B259F8BDA546A3C5132CCAEE4431CE36783,122740ibc/ED07A3391A112B175915CD8FAF43A2DA8E4790EDE12566649D0C2F97716B8518,15342624udvpn"
RESIDENTIAL_HOURLY_PRICES="18480ibc/31FEE1A2A9F9C01113F90BD0BBCCE8FD6BBB8585FAF109A2101827DD1D5B95B8,770ibc/A8C2D23A1E6F95DA4E48BA349667E322BD7A6C996D8A4AAE8BA72E190F3D1477,1871892ibc/B1C0DDB14F25279A2026BC8794E12B259F8BDA546A3C5132CCAEE4431CE36783,18897ibc/ED07A3391A112B175915CD8FAF43A2DA8E4790EDE12566649D0C2F97716B8518,10000000udvpn"

# Dynamic values
PUBLIC_ADDRESS=""
NODE_ADDRESS=""

####################################################################################################
# Configuration functions
####################################################################################################

# Function to load configuration files into variables
function load_config_files()
{
	# Load config files into variables
	NODE_MONIKER=$(grep "^moniker\s*=" "${USER_HOME}/.sentinelnode/config.toml" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	NODE_TYPE=$(grep "^type\s*=" "${USER_HOME}/.sentinelnode/config.toml" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	NODE_IP=$(grep "^remote_url\s*=" "${USER_HOME}/.sentinelnode/config.toml" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"' | awk -F"/" '{print $3}' | awk -F":" '{print $1}')
	NODE_PORT=$(grep "^listen_on\s*=" "${USER_HOME}/.sentinelnode/config.toml" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"' | awk -F":" '{print $2}')
	WIREGUARD_PORT=$(grep "^listen_port\s*=" "${USER_HOME}/.sentinelnode/wireguard.toml" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	V2RAY_PORT=$(grep "^listen_port\s*=" "${USER_HOME}/.sentinelnode/v2ray.toml" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	CHAIN_ID=$(grep "^id\s*=" "${USER_HOME}/.sentinelnode/config.toml" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	# RPC_ADDRESSES=$(grep "^rpc_addresses\s*=" "${USER_HOME}/.sentinelnode/config.toml" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	# BACKEND=$(grep "^backend\s*=" "${USER_HOME}/.sentinelnode/config.toml" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	WALLET_NAME=$(grep "^from\s*=" "${USER_HOME}/.sentinelnode/config.toml" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	
	local HOURLY_PRICES=$(grep "^hourly_prices\s*=" "${USER_HOME}/.sentinelnode/config.toml" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	
	# if hourly_prices equal to DATACENTER_HOURLY_PRICES
	if [ "$HOURLY_PRICES" == "$DATACENTER_HOURLY_PRICES" ]
	then
		NODE_LOCATION="datacenter"
	else
		NODE_LOCATION="residential"
	fi

	return 0;
}

# Function to refresh configuration files
function refresh_config_files()
{
	# Update configuration
	sed -i "s/moniker = .*/moniker = \"${NODE_MONIKER}\"/g" ${USER_HOME}/.sentinelnode/config.toml || { output_error "Failed to set moniker."; return 1; }
	
	# Update chain_id parameter
	sed -i "s/id = .*/id = \"${CHAIN_ID}\"/g" ${USER_HOME}/.sentinelnode/config.toml || { output_error "Failed to set chain ID."; return 1; }
	
	# Update rpc_addresses parameter
	sed -i "s/rpc_addresses = .*/rpc_addresses = \"${RPC_ADDRESSES//\//\\/}\"/g" ${USER_HOME}/.sentinelnode/config.toml || { output_error "Failed to set remote RPC."; return 1; }
	
	# Update node type parameter
	sed -i "s/type = .*/type = \"${NODE_TYPE}\"/g" ${USER_HOME}/.sentinelnode/config.toml || { output_error "Failed to set node type."; return 1; }
	
	# Update remote_url parameter
	sed -i "s/listen_on = .*/listen_on = \"0\\.0\\.0\\.0:${NODE_PORT}\"/g" ${USER_HOME}/.sentinelnode/config.toml || { output_error "Failed to set remote URL."; return 1; }
	
	# Update remote_url parameter
	sed -i "s/remote_url = .*/remote_url = \"https:\/\/${NODE_IP}:${NODE_PORT}\"/g" ${USER_HOME}/.sentinelnode/config.toml || { output_error "Failed to set remote URL."; return 1; }
	
	# Update backend parameter
	sed -i "s/backend = .*/backend = \"${BACKEND}\"/g" ${USER_HOME}/.sentinelnode/config.toml || { output_error "Failed to set backend."; return 1; }
	
	# Update WireGuard port
	sed -i "s/listen_port = .*/listen_port = ${WIREGUARD_PORT}/g" ${USER_HOME}/.sentinelnode/wireguard.toml || { output_error "Failed to set WireGuard port."; return 1; }
	
	# Update V2Ray port
	sed -i "s/listen_port = .*/listen_port = ${V2RAY_PORT}/g" ${USER_HOME}/.sentinelnode/v2ray.toml || { output_error "Failed to set V2Ray port."; return 1; }
	
	if [ "$NODE_LOCATION" == "residential" ]
	then
		# Update gigabyte_prices parameter
		sed -i "s/gigabyte_prices = .*/gigabyte_prices = \"${RESIDENTIAL_GIGABYTE_PRICES//\//\\/}\"/g" ${USER_HOME}/.sentinelnode/config.toml || { output_error "Failed to set gigabyte prices."; return 1; }
		
		# Update hourly_prices parameter
		sed -i "s/hourly_prices = .*/hourly_prices = \"${RESIDENTIAL_HOURLY_PRICES//\//\\/}\"/g" ${USER_HOME}/.sentinelnode/config.toml || { output_error "Failed to set hourly prices."; return 1; }
	else
		# Update gigabyte_prices parameter
		sed -i "s/gigabyte_prices = .*/gigabyte_prices = \"${DATACENTER_GIGABYTE_PRICES//\//\\/}\"/g" ${USER_HOME}/.sentinelnode/config.toml || { output_error "Failed to set gigabyte prices."; return 1; }
		
		# Update hourly_prices parameter
		sed -i "s/hourly_prices = .*/hourly_prices = \"${DATACENTER_HOURLY_PRICES//\//\\/}\"/g" ${USER_HOME}/.sentinelnode/config.toml || { output_error "Failed to set hourly prices."; return 1; }
	fi

	return 0;
}

# Function to configure network settings
function generate_sentinel_config()
{
	# If sentinel config not generated
	if [ ! -f "${USER_HOME}/.sentinelnode/config.toml" ]
	then
		# Generate Sentinel config
		docker run --rm \
			--volume ${USER_HOME}/.sentinelnode:/root/.sentinelnode \
			${CONTAINER_NAME} process config init || { output_error "Failed to generate Sentinel configuration."; return 1; }
	fi
	
	# If wireguard config not generated
	if [ ! -f "${USER_HOME}/.sentinelnode/wireguard.toml" ]
	then
		# Generate WireGuard config
		docker run --rm \
			--volume ${USER_HOME}/.sentinelnode:/root/.sentinelnode \
			${CONTAINER_NAME} process wireguard config init || { output_error "Failed to generate WireGuard configuration."; return 1; }
	fi
	
	# If v2ray config not generated
	if [ ! -f "${USER_HOME}/.sentinelnode/v2ray.toml" ]
	then
		# Generate V2Ray config
		docker run --rm \
			--volume ${USER_HOME}/.sentinelnode:/root/.sentinelnode \
			${CONTAINER_NAME} process v2ray config init || { output_error "Failed to generate V2Ray configuration."; return 1; }
	fi
	
	return 0;
}

# Function to configure network settings
function generate_certificate()
{
	# If certificate already exists, return zero
	if [ -f "${USER_HOME}/.sentinelnode/tls.crt" ] && [ -f "${USER_HOME}/.sentinelnode/tls.key" ]
	then
		return 0
	fi
	
	# Generate certificate
	openssl req -new \
	-newkey ec \
	-pkeyopt ec_paramgen_curve:prime256v1 \
	-x509 \
	-sha256 \
	-days 365 \
	-nodes \
	-out ${USER_HOME}/.sentinelnode/tls.crt \
	-subj "/C=NA/ST=NA/L=./O=NA/OU=./CN=." \
	-keyout ${USER_HOME}/.sentinelnode/tls.key || { output_error "Failed to generate certificate."; return 1; }
	
	chown root:root ${USER_HOME}/.sentinelnode/tls.crt && \
	chown root:root ${USER_HOME}/.sentinelnode/tls.key || { output_error "Failed to change ownership of certificate files."; return 1; }
	
	return 0;
}

####################################################################################################
# Utility functions
####################################################################################################

# Function to check if all dependencies are installed
function check_installation()
{
	# If curl is not installed, return false
	if ! command -v curl &> /dev/null
	then
		output_log "Curl is not installed."
		return 1
	fi
	
	# If docker is not installed, return false
	if ! command -v docker &> /dev/null
	then
		output_log "Docker is not installed."
		return 1
	fi
	
	# If user is not in docker group, return false
	if ! groups "$SUDO_USER" | grep -q "\bdocker\b"
	then
		output_log "User $SUDO_USER is not in the Docker group."
		return 1
	fi
	
	# If sentinel docker image not installed, return false
	if ! docker image inspect ${CONTAINER_NAME} &> /dev/null
	then
		output_log "Sentinel Docker image is not installed."
		return 1
	fi
	
	# If sentinel config not generated, return false
	if [ ! -f "${USER_HOME}/.sentinelnode/config.toml" ]
	then
		output_log "Sentinel config is not generated."
		return 1
	fi
	
	# If wireguard config not generated, return false
	if [ ! -f "${USER_HOME}/.sentinelnode/wireguard.toml" ]
	then
		output_log "WireGuard config is not generated."
		return 1
	fi
	
	# If v2ray config not generated, return false
	if [ ! -f "${USER_HOME}/.sentinelnode/v2ray.toml" ]
	then
		output_log "V2Ray config is not generated."
		return 1
	fi
	
	# If container is not initialized, return false
	if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
	then
		output_log "Sentinel container is not initialized."
		return 1
	fi
	
	return 0;
}

# Function to output log messages
function output_log()
{
	if [ "$OUTPUT_DEBUG" = true ]; then
		local message="$1"
		echo -e "\e[34m${message}\e[0m"
	fi
}

# Function to output information messages
function output_info()
{
	local message="$1"
	echo -e "\e[32m${message}\e[0m"
}

# Function to output error messages
function output_error()
{
	local error="$1"
	echo -e "\e[31m${error}\e[0m"
	whiptail --title "Error" --msgbox "${error}" 8 78
	exit 1
}

# Function to check if the OS is Ubuntu (Source: https://github.com/roomit-xyz/sentinel-node/blob/main/sentinel-node.sh)
function os_ubuntu()
{
	# Check if the OS is Ubuntu
	os_name=$(lsb_release -is)
	if [[ "$os_name" != "Ubuntu" ]]
	then
		return 1
	fi

	version=$(lsb_release -rs)
	if [[ "$version" == "18."* || "$version" == "19."* || "$version" == "20."* || \
		"$version" == "21."* || "$version" == "22."* || "$version" == "23."* || \
		"$version" == "24."* ]]
	then
		return 0  
	else
		return 1  
	fi
}

# Function to check if the OS is Raspbian (Source: https://github.com/roomit-xyz/sentinel-node/blob/main/sentinel-node.sh)
function os_raspbian()
{
	raspbian_check=$(cat /etc/*-release | grep "ID=raspbian" | wc -l)
	arm_check=$(uname -a | egrep "aarch64|arm64|armv7" | wc -l)
	if [ ${raspbian_check} == 1 ] || [ ${arm_check} == 1 ]
	then
		return 0  
	else
		return 1 
	fi
}

####################################################################################################
# Docker functions
####################################################################################################

# Function to install Docker if not already installed
function install_docker()
{
	# Check if Docker is installed return 0
	if command -v docker &> /dev/null
	then
		# Check if the user is in the docker group
		if ! groups | grep -q "\bdocker\b"
		then
			# Add the current user to the Docker group if not already a member
			docker_usermod || return 1;
			# Ask user to reboot the system
			message_docker_reboot_required
		else
			return 0;
		fi
	fi
	
	# Install dependencies
	apt install -y curl git openssl || { output_error "Failed to install dependencies."; return 1; }
	
	# Download and execute the Docker installation script
	set -o pipefail
	curl -fsSL get.docker.com | sh || { output_error "Failed to install Docker."; return 1; }
	
	# Enable and start the Docker service
	systemctl enable --now docker || { output_error "Failed to enable Docker."; return 1; }
	
	# Add the current user to the Docker group
	usermod -aG docker $(whoami) || { output_error "Failed to add user to Docker group."; return 1; }
	
	# Add the current user to the Docker group if not already a member
	docker_usermod || return 1;
	
	# Check if Docker is now installed
	if ! command -v docker &> /dev/null
	then
		output_error "Docker installation failed.";
		return 1;
	else
		# Ask user to reboot the system
		message_docker_reboot_required
	fi
	
	return 0;
}

# Function to check if the user is in the docker group and add them if not
function docker_usermod()
{
	# Check if the user is in the docker group
	if ! groups | grep -q "\bdocker\b"; then
		# Add the user to the docker group
		usermod -aG docker ${USER_NAME} || { output_error "Failed to add user to docker group."; return 1; }
		output_log "User added to docker group."
	fi
	
	return 0;
}


####################################################################################################
# Container functions
####################################################################################################

# Function to install sentinel image
function container_install()
{
	# Check if image already downloaded
	if docker image inspect ${CONTAINER_NAME} &> /dev/null
	then
		return 0
	fi
	
	if os_ubuntu
	then
		IMAGE="ghcr.io/sentinel-official/dvpn-node:latest"
	elif os_raspbian
	then
		if [[ $(arch) == "arm"* ]]
		then
			IMAGE="wajatmaka/sentinel-arm7-debian:v0.7.1"
		elif [[ $(arch) == "aarch64"* ]] || [[ $(arch) == "arm64"* ]]
		then
			IMAGE="wajatmaka/sentinel-aarch64-alpine:v0.7.1"
		else
			output_error "Unsupported architecture. Please use ARMv7 or ARM64."
			return 1
		fi
	else
		output_error "Unsupported OS. Please use Ubuntu or Raspbian."
		return 1
	fi
	
	# Pull the Sentinel image
	output_info "Pulling the Sentinel image, please wait..."
	docker pull ${IMAGE} || { output_error "Failed to pull the Sentinel image."; return 1; }
	docker tag ${IMAGE} ${CONTAINER_NAME} || { output_error "Failed to tag the Sentinel image."; return 1; }
	
	return 0;
}

# Function to start the Docker container
function container_start()
{
	# Read config file and check type of node
	TYPE=$(cat ${USER_HOME}/.sentinelnode/config.toml | grep "type" | awk -F" = " '{print $2}' | tr -d '"')
	
	# If container is already created, check if it is running
	if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
	then
		# Check if the container is not running
		if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
			# Container is not running, attempt to start it
			docker start ${CONTAINER_NAME} || { output_error "Failed to start the Sentinel container."; return 1; }
		fi
		return 0
	fi

	# If node type is wireguard
	if [ "$TYPE" == "wireguard" ]
	then
		# Start WireGuard node
		docker run -d \
			--name ${CONTAINER_NAME} \
			--restart unless-stopped \
			--volume ${USER_HOME}/.sentinelnode:/root/.sentinelnode \
			--volume /lib/modules:/lib/modules \
			--cap-drop ALL \
			--cap-add NET_ADMIN \
			--cap-add NET_BIND_SERVICE \
			--cap-add NET_RAW \
			--cap-add SYS_MODULE \
			--sysctl net.ipv4.ip_forward=1 \
			--sysctl net.ipv6.conf.all.disable_ipv6=0 \
			--sysctl net.ipv6.conf.all.forwarding=1 \
			--sysctl net.ipv6.conf.default.forwarding=1 \
			--publish ${NODE_PORT}:${NODE_PORT}/tcp \
			--publish ${WIREGUARD_PORT}:${WIREGUARD_PORT}/udp \
			${CONTAINER_NAME} process start || { output_error "Failed to start WireGuard node."; return 1; }
	elif [ "$TYPE" == "v2ray" ]
	then
		# Start V2Ray node
		docker run -d \
			--name ${CONTAINER_NAME} \
			--restart unless-stopped \
			--volume "${USER_HOME}/.sentinelnode:/root/.sentinelnode" \
			--publish ${NODE_PORT}:${NODE_PORT}/tcp \
			--publish ${V2RAY_PORT}:${V2RAY_PORT}/tcp \
			${CONTAINER_NAME} process start || { output_error "Failed to start V2Ray node."; return 1; }
	else
		output_error "Invalid node type."
		return 1
	fi
	
	return 0;
}

# Function to stop the Docker container
function container_stop()
{
	docker stop ${CONTAINER_NAME} || { output_error "Failed to stop the Sentinel container."; return 1; }
	return 0;
}

# Function to restart the Docker container
function container_restart()
{
	docker restart ${CONTAINER_NAME} || { output_error "Failed to restart the Sentinel container."; return 1; }
	return 0;
}

# Function to check if the Docker container is running
function container_running()
{
	if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
	then
		return 0
	else
		return 1
	fi
}

####################################################################################################
# Wallet functions
####################################################################################################

function wallet_initialization()
{
	# Check if wallet exists
	if docker run --rm --interactive --tty --volume ${USER_HOME}/.sentinelnode:/root/.sentinelnode ${CONTAINER_NAME} process keys list | grep -q "sentnode"
	then
		# Ask user if they want to delete the existing wallet
		if whiptail --title "Wallet Exists" --yesno "A wallet already exists. Do you want to delete the existing wallet and continue?" 8 78
		then
			# Delete existing wallet
			docker run --rm \
				--interactive \
				--tty \
				--volume ${USER_HOME}/.sentinelnode:/root/.sentinelnode \
				${CONTAINER_NAME} process keys delete
		else
			output_log "Wallet already exists."
			return 0;
		fi
	else
		output_log "No wallet found."
	fi
	
	# Ask if user wants to restore wallet
	if whiptail --title "Wallet Initialization Confirmation" --yesno "Do you want to restore an existing Sentinel wallet? Please note that this wallet should be dedicated to this node and not used with any other nodes." 8 78
	then
		
		# Ask for mnemonic and store un MNEMONIC variable
		MNEMONIC=$(whiptail --inputbox "Please enter your wallet's mnemonic:" 8 78 --title "Wallet Mnemonic" 3>&1 1>&2 2>&3) || { output_error "Failed to get mnemonic."; return 1; }
		
		# Restore wallet
		output_info "Restoring wallet, please wait..."
		echo "$MNEMONIC" | docker run --rm \
			--interactive \
			--volume ${USER_HOME}/.sentinelnode:/root/.sentinelnode \
			${CONTAINER_NAME} process keys add --recover || { output_error "Failed to restore wallet."; return 1; }
	else
		# Create new wallet
		output_info "Creating new wallet, please wait..."
		OUTPUT=$(docker run --rm \
					--interactive \
					--tty \
					--volume ${USER_HOME}/.sentinelnode:/root/.sentinelnode \
					${CONTAINER_NAME} process keys add)
		
		# output_log "Wallet creation output: ${OUTPUT}"
		
		# If the ouput contains "Important" then extract the mnemonic
		if echo "$OUTPUT" | grep -q "Important"
		then
			MNEMONIC=$(echo "$OUTPUT" | awk '/Important/{flag=1; next} /Name/{flag=0} flag' | sed 's/[ \t\n]*$//')
		else
			output_error "Failed to get mnemonic: $OUTPUT"
			return 1
		fi
		
		# Remove end of line
		MNEMONIC=$(echo "$MNEMONIC" | tr -d '\r')
		
		# Découpage intelligent en groupes de mots
		formatted_mnemonic=$(echo "$MNEMONIC" | tr -s ' ' '\n' | awk '{
			printf "%d. %s ", NR, $0;
			if (NR % 4 == 0) print "";
		} END {
			if (NR % 4 != 0) print "";
		}' | tr -d '\r')
		
		# Affichage
		whiptail --title "Wallet Mnemonic" --msgbox "Please save the following mnemonic. This will be required to restore your wallet in the future.\n\nMnemonic:\n${formatted_mnemonic}" 20 100
		
	fi
	
	output_log "Wallet initialized."
	
	return 0;
}

# Function to check if wallet exists
function wallet_exist()
{
	# Check if a wallet with the specified name exists
	local wallet_list_output
	wallet_list_output=$(docker run --rm \
		--interactive \
		--tty \
		--volume "${USER_HOME}/.sentinelnode:/root/.sentinelnode" \
		"${CONTAINER_NAME}" process keys list)

	# Use grep to check if the wallet name is in the list
	if echo "$wallet_list_output" | grep -q "$WALLET_NAME"; then
		return 0  # Wallet exists
	else
		return 1  # Wallet does not exist
	fi
}

# Function to remove the wallet
function wallet_remove()
{
	# If wallet does not exist, return 0
	if ! wallet_exist
	then
		return 0;
	fi
	
	# Delete existing wallet
	docker run --rm \
		--interactive \
		--tty \
		--volume ${USER_HOME}/.sentinelnode:/root/.sentinelnode \
		${CONTAINER_NAME} process keys delete $WALLET_NAME || { output_error "Failed to delete wallet."; return 1; }
	
	return 0;
}

# Function to get the public and node addresses of the wallet
function wallet_addresses()
{
	# Show waiting message
	output_info "Please wait while the wallet addresses are being retrieved..."

	# Execute Docker command once and store output
	local WALLET_INFO=$(docker run --rm \
		--interactive \
		--tty \
		--volume "${USER_HOME}/.sentinelnode:/root/.sentinelnode" \
		"${CONTAINER_NAME}" process keys show | awk -v name="$WALLET_NAME" '$1 == name')

	# Extract public and node addresses from the output
	PUBLIC_ADDRESS=$(echo "$WALLET_INFO" | awk '{print $3}')
	NODE_ADDRESS=$(echo "$WALLET_INFO" | awk '{print $2}')
	
	# Remove end of line
	PUBLIC_ADDRESS=$(echo "$PUBLIC_ADDRESS" | tr -d '\r')
	NODE_ADDRESS=$(echo "$NODE_ADDRESS" | tr -d '\r')
	
	return 0;
}


####################################################################################################
# Firewall functions
####################################################################################################

# Function to open the firewall
function firewall_configure()
{
	# Ask if user wants to configure the firewall
	if ! whiptail --title "Firewall Configuration" --defaultno --yesno "Do you want to configure the firewall to allow incoming connections to the node?" 8 78
	then
		return 0;
	fi
	
	# Check if UFW is not installed
	if ! command -v ufw &> /dev/null
	then
		# Install UFW
		output_info "Installing UFW, please wait..."
		apt install -y ufw || { output_error "Failed to install UFW."; return 1; }
	fi
	
	# Enable UFW
	echo "y" | ufw enable > /dev/null 2>&1 || { output_error "Failed to enable UFW."; return 1; }
	
	# Allow Node port
	if ! ufw status | grep -q "${NODE_PORT}/tcp"
	then
		ufw allow ${NODE_PORT}/tcp > /dev/null 2>&1 || { output_error "Failed to allow node port."; return 1; }
	fi
	
	# Allow WireGuard
	if ! ufw status | grep -q "${WIREGUARD_PORT}/tcp"
	then
		ufw allow ${WIREGUARD_PORT}/tcp > /dev/null 2>&1 || { output_error "Failed to allow WireGuard."; return 1; }
	fi
	
	# Allow V2Ray
	if ! ufw status | grep -q "${V2RAY_PORT}/udp"
	then
		ufw allow ${V2RAY_PORT}/udp > /dev/null 2>&1 || { output_error "Failed to allow V2Ray."; return 1; }
	fi
	
	# Reload UFW
	ufw reload > /dev/null 2>&1 || { output_error "Failed to reload UFW."; return 1; }
	
	return 0;
}

####################################################################################################
# Prompt functions
####################################################################################################

# Function to ask for remote IP
function ask_remote_ip()
{
	# If NODE_IP egale to 0.0.0.0 or empty, then retrieve the current public IP
	if [ "$NODE_IP" = "0.0.0.0" ] || [ -z "$NODE_IP" ];
	then
		# Retrieve the current public IP using wget and sed
		NODE_IP=$(wget -q -O - checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
	fi
	
	# Ask for remote IP
	NODE_IP=$(whiptail --inputbox "Please enter your node's public IP address:" 8 78 "$NODE_IP" --title "Node IP" 3>&1 1>&2 2>&3) || { output_error "Failed to get node IP."; return 1; }
	
	return 0;
}

# Function to ask for node location
function ask_node_location()
{
	# Set initial state based on current $NODE_LOCATION
	local datacenter_state="OFF"
	local residential_state="OFF"

	if [ "$NODE_LOCATION" == "datacenter" ]; then
		datacenter_state="ON"
	elif [ "$NODE_LOCATION" == "residential" ]; then
		residential_state="ON"
	fi

	# Ask for node location using whiptail
	NODE_LOCATION=$(whiptail --title "Node Location" --radiolist "Please select the type of validation node you want to run:" 15 78 2 \
		"datacenter" "Datacenter" $datacenter_state \
		"residential" "Residential" $residential_state 3>&1 1>&2 2>&3) || { output_error "Failed to get validation node type."; return 1; }

	return 0;
}

# Function to ask for node type
function ask_node_type()
{
	# Set initial state based on current $NODE_TYPE
	local wireguard_state="OFF"
	local v2ray_state="OFF"

	if [ "$NODE_TYPE" == "wireguard" ]; then
		wireguard_state="ON"
	elif [ "$NODE_TYPE" == "v2ray" ]; then
		v2ray_state="ON"
	fi

	# Ask for node type using whiptail
	NODE_TYPE=$(whiptail --title "Node Type" --radiolist "Please select the type of node you want to run:" 15 78 2 \
		"wireguard" "WireGuard" $wireguard_state \
		"v2ray" "V2Ray" $v2ray_state 3>&1 1>&2 2>&3) || { output_error "Failed to get node type."; return 1; }

	return 0;
}

# Function to ask for max peers
function ask_max_peers()
{
	# Ask for max peers
	MAX_PEERS=$(whiptail --inputbox "Please enter the maximum number of peers you want to connect to:" 8 78 "$MAX_PEERS" --title "Max Peers" 3>&1 1>&2 2>&3) || { output_error "Failed to get max peers."; return 1; }
	return 0;
}

# Function to ask for moniker
function ask_moniker()
{
	# Ask for moniker
	NODE_MONIKER=$(whiptail --inputbox "Please enter your node's moniker:" 8 78 "$NODE_MONIKER" --title "Node Moniker" 3>&1 1>&2 2>&3) || { output_error "Failed to get moniker."; return 1; }
	return 0;
}

####################################################################################################
# Messages functions
####################################################################################################

# Function to display a message to wait for funds
function message_wait_funds()
{
	# Get public address
	wallet_addresses || { output_error "Failed to get public address."; return 1; }
	
	# If public address doesn't start with "sent" then return error
	if [[ ! ${PUBLIC_ADDRESS} == "sent"* ]]; then
		output_error "Invalid public address."
		return 1
	fi
	
	# Display message to wait for funds
	whiptail --title "Funds Required" --msgbox "Please send at least 50 \$DVPN to the following address before continuing and starting the node: ${PUBLIC_ADDRESS}" 8 78
	
	return 0;
}

# Function to display a message to inform about Docker installation and reboot requirement
function message_docker_reboot_required()
{
	# Display message to inform about Docker installation and reboot requirement
	if whiptail --title "Docker Installation Complete" --yesno "Docker has been successfully installed on your system. For the installation to take full effect, a system reboot is required. Please select 'Reboot Now' to restart your system immediately, or choose 'Quit Without Reboot' if you prefer to reboot later at your own convenience." 12 78 --yes-button "Reboot Now" --no-button "Quit Without Reboot"; then
		# Reboot the system
		echo "Rebooting now..."
		reboot
	else
		# Quit without rebooting
		echo "Installation complete. Please reboot your system before continuing."
		exit 0
	fi
}

####################################################################################################
# Menu functions
####################################################################################################

# Function to display the installation menu
function menu_installation()
{

	# Check if whiptail is not installed
	if ! command -v whiptail &> /dev/null
	then
		# Install whiptail
		apt install -y whiptail || { echo -e "\e[31mFailed to install whiptail.\e[0m"; return 1; }
	fi

	# Check if jq is not installed
	if ! command -v jq &> /dev/null
	then
		# Install jq
		apt install -y jq || { output_error "Failed to install jq."; return 1; }
	fi

	if ! whiptail --title "Welcome to Sentinel Installation" --yesno "Welcome to the Sentinel installation process. This installation will be done in multiple steps and you will be guided throughout the process. Do you want to continue with the installation process?" 10 78
	then
		echo "Installation process skipped."
		# Stop script execution
		exit 0
	fi
	
	install_docker || return 1;
	
	container_install || return 1;
	
	if [ ! -d "${USER_HOME}/.sentinelnode" ]; then
		mkdir ${USER_HOME}/.sentinelnode || { output_error "Failed to create Sentinel node directory."; return 1; }
	fi
	
	generate_certificate || return 1;
	
	generate_sentinel_config || return 1;

	load_config_files || return 1;
	
	ask_moniker || return 1;
	
	ask_node_location || return 1;

	ask_node_type || return 1;
	
	ask_remote_ip || return 1;
	
	refresh_config_files || return 1;
	
	firewall_configure || return 1;
	
	wallet_initialization || return 1;
	
	message_wait_funds || return 1;
	
	# Start the Sentinel node
	container_start || return 1;
	
	# Display message to user
	whiptail --title "Installation Complete" --msgbox "The Sentinel node has been successfully installed and started!\nYou can now access the node dashboard by visiting the following URL:\n\nhttps://${NODE_IP}:${NODE_PORT}/status" 12 100
	
	return 0;
}

# Function to display the configuration menu
function menu_configuration()
{
	# Load configuration into variables
	load_config_files || return 1;

	choice=$(whiptail --title "Welcome to Sentinel Configuration" --menu "Welcome to the Sentinel configuration process. Please select an option:" 15 78 5 \
		"Settings" "Change node configuration" \
		"Wallet" "View wallet information" \
		"Node" "Perform node actions" \
		"Update" "Update the node" \
		--ok-button "Select" --cancel-button "Finish" 3>&1 1>&2 2>&3)

	if [ $? -eq 1 ]; then  # Check if the user pressed the 'Finish' button, which is the cancel button now
		exit 0
	fi

	# Handle selected option
	case $choice in
		"Settings")
			menu_settings
			;;
		"Wallet")
			menu_wallet
			;;
		"Node")
			menu_node
			;;
		"Update")
			menu_update
			;;
	esac
}
# Function to display the settings menu
function menu_settings()
{
	while true;
	do
		CHOICE=$(whiptail --title "Node Settings" --menu "Choose a settings group to configure:" 15 60 5 \
			"1" "Node Settings" \
			"2" "Network Settings" \
			"3" "VPN Settings" \
			--cancel-button "Back" --ok-button "Select" 3>&1 1>&2 2>&3)

		EXITSTATUS=$?
		if [ $EXITSTATUS -eq 1 ]; then
			# If user chooses 'Back', break the loop to return to previous menu
			break
		fi

		case $CHOICE in
			1)
				ask_moniker || return 1;
				ask_node_location || return 1;

				refresh_config_files || return 1;
				container_restart || return 1;
				# Display message indicating that the settings have been updated
				whiptail --title "Settings Updated" --msgbox "Node settings have been updated." 8 78
				;;
			2)
				ask_remote_ip || return 1;

				refresh_config_files || return 1;
				container_restart || return 1;
				# Display message indicating that the settings have been updated
				whiptail --title "Settings Updated" --msgbox "Network settings have been updated." 8 78
				;;
			3)
				ask_node_type || return 1;
				ask_max_peers || return 1;

				refresh_config_files || return 1;
				container_restart || return 1;
				# Display message indicating that the settings have been updated
				whiptail --title "Settings Updated" --msgbox "VPN settings have been updated." 8 78
				;;
		esac
	done
}

# Function to display the wallet menu
function menu_wallet()
{
	# Load configuration into variables
	wallet_addresses || return 1;

	# Get wallet balance
	AMOUNT_BALANCE=$(curl -s https://wapi.foxinodes.net/api/v1/address/${PUBLIC_ADDRESS} | jq -r '.addresses[0].available')
	while true
	do
		# Display wallet information and prompt for next action
		if whiptail --title "Wallet Information" --yes-button "Back" --no-button "Remove Wallet" --yesno "Public Address: ${PUBLIC_ADDRESS}\nNode Address: ${NODE_ADDRESS}\nDVPN Balance: ${AMOUNT_BALANCE}" 12 78
		then
			return 0;
		else
			# Confirm wallet removal
			if whiptail --title "Confirm Removal" --yesno "Are you sure you want to remove the wallet address?" 8 78
			then
				# Remove wallet
				# wallet_remove || return 1;

				# Initialize new wallet
				wallet_initialization || return 1;
			fi
		fi
	done
}

# Function to display the node menu
function menu_node()
{
	local choice=""
	local status_msg=""

	while true
	do
		# Check if the container is running
		if container_running
		then
			status_msg="Node Status: Running"
			choice=$(whiptail --title "Sentinel Node Menu" --menu "$status_msg\nChoose an option:" 15 78 4 \
				"Restart" "Restart Sentinel Node" \
				"Stop" "Stop Sentinel Node" \
				"Back" "Return to previous menu" 3>&1 1>&2 2>&3)
		else
			status_msg="Node Status: Stopped"
			choice=$(whiptail --title "Sentinel Node Menu" --menu "$status_msg\nChoose an option:" 15 78 3 \
				"Start" "Start Sentinel Node" \
				"Back" "Return to previous menu" 3>&1 1>&2 2>&3)
		fi

		# Handle selected option
		case $choice in
			"Restart")
				container_restart
				;;
			"Stop")
				container_stop
				;;
			"Start")
				container_start
				;;
			*)
				break
				;;
		esac
	done
}

# Function to update the Sentinel image
function menu_update()
{
	container_install || return 1;

	container_restart || return 1;

	# Display message indicating that the image is up to date
	whiptail --title "Update Complete" --msgbox "Sentinel image is up to date." 8 78

	return 0;
}


####################################################################################################
# Main function
####################################################################################################

# Check if the script is executed with sudo permissions
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run with sudo permissions"
	exit 1
fi

while true
do
	# Check if installation already exists
	if check_installation
	then
		menu_configuration;
	else
		menu_installation;
		exit 0;
	fi
done
