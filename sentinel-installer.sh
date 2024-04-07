#!/bin/bash

# Variables
OUTPUT_DEBUG=true
FIREWALL="ufw"
NODE_MONIKER=""
NODE_TYPE="wireguard"
NODE_IP="0.0.0.0"
NODE_PORT=16567
WIREGUARD_PORT=16568
V2RAY_PORT=16568
CHAIN_ID="sentinelhub-2"
RPC_ADDRESSES="https://rpc.sentinel.co:443,https://rpc.sentinel.quokkastake.io:443,https://rpc.trinityvalidator.com:443"
GIGABYTE_PRICES="52573ibc/31FEE1A2A9F9C01113F90BD0BBCCE8FD6BBB8585FAF109A2101827DD1D5B95B8,9204ibc/A8C2D23A1E6F95DA4E48BA349667E322BD7A6C996D8A4AAE8BA72E190F3D1477,1180852ibc/B1C0DDB14F25279A2026BC8794E12B259F8BDA546A3C5132CCAEE4431CE36783,122740ibc/ED07A3391A112B175915CD8FAF43A2DA8E4790EDE12566649D0C2F97716B8518,15342624udvpn"
HOURLY_PRICES="18480ibc/31FEE1A2A9F9C01113F90BD0BBCCE8FD6BBB8585FAF109A2101827DD1D5B95B8,770ibc/A8C2D23A1E6F95DA4E48BA349667E322BD7A6C996D8A4AAE8BA72E190F3D1477,1871892ibc/B1C0DDB14F25279A2026BC8794E12B259F8BDA546A3C5132CCAEE4431CE36783,18897ibc/ED07A3391A112B175915CD8FAF43A2DA8E4790EDE12566649D0C2F97716B8518,4160000udvpn"
BACKEND="test"

function output_log()
{
	if [ "$OUTPUT_DEBUG" = true ]; then
		local message="$1"
		echo -e "\e[32m${message}\e[0m"
	fi

}

function output_error()
{
	local error="$1"
	echo -e "\e[31m${error}\e[0m"
	whiptail --title "Error" --msgbox "${error}" 8 78
	exit 1
}

function os_ubuntu()
{
	version=$(lsb_release -rs)
	if [[ "$version" == "18."* || "$version" == "19."* || "$version" == "20."* || "$version" == "21."* || "$version" == "22."* || "$version" == "23."* ]]; then
		return 0  
	else
		return 1  
	fi
}

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

function start_node()
{
	# Read config file and check type of node
	TYPE=$(sudo cat ${HOME}/.sentinelnode/config.toml | grep "type" | awk -F" = " '{print $2}' | tr -d '"')
	
	# If node type is wireguard
	if [ "$TYPE" == "wireguard" ]
	then
		# Start WireGuard node
		sudo docker run -d \
			--name sentinel-dvpn-node \
			--restart unless-stopped \
			--volume ${HOME}/.sentinelnode:/root/.sentinelnode \
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
			sentinel-dvpn-node process start || { output_error "Failed to start WireGuard node."; return 1; }
	elif [ "$TYPE" == "v2ray" ]
	then
		# Start V2Ray node
		sudo docker run -d \
			--restart unless-stopped \
			--volume "${HOME}/.sentinelnode:/root/.sentinelnode" \
			--publish ${NODE_PORT}:${NODE_PORT}/tcp \
			--publish ${V2RAY_PORT}:${V2RAY_PORT}/tcp \
			sentinel-dvpn-node process start || { output_error "Failed to start V2Ray node."; return 1; }
	else
		output_error "Invalid node type."
		return 1
	fi
	
	return 0;
}

function wait_funds()
{
	PUBLIC_ADDRESS=$(docker run --rm \
		--interactive \
		--tty \
		--volume ${HOME}/.sentinelnode:/root/.sentinelnode \
		sentinel-dvpn-node process keys show | awk 'NR==2{print $3}')
	
	# If public address doesn't start with "sent" then return error
	if [[ ! ${PUBLIC_ADDRESS} == "sent"* ]]; then
		output_error "Invalid public address."
		return 1
	fi
	
	# Display message to ask for funds
	whiptail --title "Funds Required" --msgbox "Please send at least 50 \$DVPN to the following address before continuing and starting the node: ${PUBLIC_ADDRESS}" 8 78
	
	return 0;
}

function refresh_config_files()
{
	# Update configuration
	sudo sed -i "s/moniker = .*/moniker = \"${MONIKER}\"/g" ${HOME}/.sentinelnode/config.toml || { output_error "Failed to set moniker."; return 1; }
	
	# Update chain_id parameter
	sudo sed -i "s/id = .*/id = \"${CHAIN_ID}\"/g" ${HOME}/.sentinelnode/config.toml || { output_error "Failed to set chain ID."; return 1; }
	
	# Update rpc_addresses parameter
	sudo sed -i "s/rpc_addresses = .*/rpc_addresses = \"${RPC_ADDRESSES//\//\\/}\"/g" ${HOME}/.sentinelnode/config.toml || { output_error "Failed to set remote RPC."; return 1; }
	
	# Update node type parameter
	sudo sed -i "s/type = .*/type = \"${NODE_TYPE}\"/g" ${HOME}/.sentinelnode/config.toml || { output_error "Failed to set node type."; return 1; }
	
	# Update remote_url parameter
	sudo sed -i "s/listen_on = .*/listen_on = \"0\\.0\\.0\\.0:${NODE_PORT}\"/g" ${HOME}/.sentinelnode/config.toml || { output_error "Failed to set remote URL."; return 1; }
	
	# Update gigabyte_prices parameter
	sudo sed -i "s/gigabyte_prices = .*/gigabyte_prices = \"${GIGABYTE_PRICES//\//\\/}\"/g" ${HOME}/.sentinelnode/config.toml || { output_error "Failed to set gigabyte prices."; return 1; }
	
	# Update hourly_prices parameter
	sudo sed -i "s/hourly_prices = .*/hourly_prices = \"${HOURLY_PRICES//\//\\/}\"/g" ${HOME}/.sentinelnode/config.toml || { output_error "Failed to set hourly prices."; return 1; }
	
	# Update remote_url parameter
	sudo sed -i "s/remote_url = .*/remote_url = \"https:\/\/${NODE_IP}:${NODE_PORT}\"/g" ${HOME}/.sentinelnode/config.toml || { output_error "Failed to set remote URL."; return 1; }
	
	# Update backend parameter
	sudo sed -i "s/backend = .*/backend = \"${BACKEND}\"/g" ${HOME}/.sentinelnode/config.toml || { output_error "Failed to set backend."; return 1; }
	
	# Update WireGuard port
	sudo sed -i "s/listen_port = .*/listen_port = ${WIREGUARD_PORT}/g" ${HOME}/.sentinelnode/wireguard.toml || { output_error "Failed to set WireGuard port."; return 1; }
	
	# Update V2Ray port
	sudo sed -i "s/listen_port = .*/listen_port = ${V2RAY_PORT}/g" ${HOME}/.sentinelnode/v2ray.toml || { output_error "Failed to set V2Ray port."; return 1; }
	
	return 0;
}


function initialize_wallet()
{
	# Check if wallet exists
	if docker run --rm --interactive --tty --volume ${HOME}/.sentinelnode:/root/.sentinelnode sentinel-dvpn-node process keys list | grep -q "sentnode"
	then
		# Ask user if they want to delete the existing wallet
		if whiptail --title "Wallet Exists" --yesno "A wallet already exists. Do you want to delete the existing wallet and continue?" 8 78
		then
			# Delete existing wallet
			sudo docker run --rm \
				--interactive \
				--tty \
				--volume ${HOME}/.sentinelnode:/root/.sentinelnode \
				sentinel-dvpn-node process keys delete
		else
			return 0;
		fi
	fi
	
	# Ask if user wants to restore wallet
	if whiptail --title "Wallet Initialization Confirmation" --yesno "Do you want to restore an existing Sentinel wallet? Please note that this wallet should be dedicated to this node and not used with any other nodes." 8 78
	then
		
		# Ask for mnemonic and store un MNEMONIC variable
		MNEMONIC=$(whiptail --inputbox "Please enter your wallet's mnemonic:" 8 78 --title "Wallet Mnemonic" 3>&1 1>&2 2>&3) || { output_error "Failed to get mnemonic."; return 1; }
		
		# Restore wallet
		echo "$MNEMONIC" | sudo docker run --rm \
			--interactive \
			--volume ${HOME}/.sentinelnode:/root/.sentinelnode \
			sentinel-dvpn-node process keys add --recover || { output_error "Failed to restore wallet."; return 1; }
	else
		# Create new wallet
		OUTPUT=$(docker run --rm \
					--interactive \
					--tty \
					--volume ${HOME}/.sentinelnode:/root/.sentinelnode \
					sentinel-dvpn-node process keys add)
		
		output_log "Wallet creation output: ${OUTPUT}"
		
		# If the ouput contains "Important" then extract the mnemonic
		if echo "$OUTPUT" | grep -q "Important"
		then
			MNEMONIC=$(echo "$OUTPUT" | awk '/Important/{flag=1; next} /Name/{flag=0} flag' | sed 's/[ \t\n]*$//')
		else
			output_error "Failed to get mnemonic: $OUTPUT"
			return 1
		fi
		
		output_log "Wallet mnemonic: ${MNEMONIC}"
		
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
	
	return 0;
}

function open_firewall()
{
	# Check if UFW is not installed
	if ! command -v ufw &> /dev/null
	then
		# Install UFW
		sudo apt install -y ufw || { output_error "Failed to install UFW."; return 1; }
	fi
	
	# Enable UFW
	sudo echo "y" | sudo ufw enable > /dev/null 2>&1 || { output_error "Failed to enable UFW."; return 1; }
	
	# Allow Node port
	if ! sudo ufw status | grep -q "${NODE_PORT}/tcp"
	then
		sudo ufw allow ${NODE_PORT}/tcp > /dev/null 2>&1 || { output_error "Failed to allow node port."; return 1; }
	fi
	
	# Allow WireGuard
	if ! sudo ufw status | grep -q "${WIREGUARD_PORT}/tcp"
	then
		sudo ufw allow ${WIREGUARD_PORT}/tcp > /dev/null 2>&1 || { output_error "Failed to allow WireGuard."; return 1; }
	fi
	
	# Allow V2Ray
	if ! sudo ufw status | grep -q "${V2RAY_PORT}/udp"
	then
		sudo ufw allow ${V2RAY_PORT}/udp > /dev/null 2>&1 || { output_error "Failed to allow V2Ray."; return 1; }
	fi
	
	# Reload UFW
	sudo ufw reload > /dev/null 2>&1 || { output_error "Failed to reload UFW."; return 1; }
	
	return 0;
}

function ask_remote_ip()
{
	# Ask for remote IP
	NODE_IP=$(whiptail --inputbox "Please enter your node's public IP address:" 8 78 --title "Node IP" 3>&1 1>&2 2>&3) || { output_error "Failed to get node IP."; return 1; }
	
	# Update configuration
	refresh_config_files || return 1;
	
	return 0;
}

function ask_node_type()
{
	NODE_TYPE=$(whiptail --title "Node Type" --radiolist "Please select the type of node you want to run:" 15 78 2 \
		"wireguard" "WireGuard" ON \
		"v2ray" "V2Ray" OFF 3>&1 1>&2 2>&3) || { output_error "Failed to get node type."; return 1; }
	
	# Update configuration
	refresh_config_files || return 1;
	
	return 0;
}

function ask_moniker()
{
	# Ask for moniker
	MONIKER=$(whiptail --inputbox "Please enter your node's moniker:" 8 78 --title "Node Moniker" 3>&1 1>&2 2>&3) || { output_error "Failed to get moniker."; return 1; }
	
	# Update configuration
	refresh_config_files || return 1;
	
	return 0;
}

function generate_sentinel_config()
{
	# If sentinel config not generated
	if [ ! -f "${HOME}/.sentinelnode/config.toml" ]
	then
		# Generate Sentinel config
		sudo docker run --rm \
			--volume ${HOME}/.sentinelnode:/root/.sentinelnode \
			sentinel-dvpn-node process config init || { output_error "Failed to generate Sentinel configuration."; return 1; }
	fi
	
	# If wireguard config not generated
	if [ ! -f "${HOME}/.sentinelnode/wireguard.toml" ]
	then
		# Generate WireGuard config
		sudo docker run --rm \
			--volume ${HOME}/.sentinelnode:/root/.sentinelnode \
			sentinel-dvpn-node process wireguard config init || { output_error "Failed to generate WireGuard configuration."; return 1; }
	fi
	
	# If v2ray config not generated
	if [ ! -f "${HOME}/.sentinelnode/v2ray.toml" ]
	then
		# Generate V2Ray config
		sudo docker run --rm \
			--volume ${HOME}/.sentinelnode:/root/.sentinelnode \
			sentinel-dvpn-node process v2ray config init || { output_error "Failed to generate V2Ray configuration."; return 1; }
	fi
	
	# Refresh configuration files and don't ouput errors
	refresh_config_files || return 1;
	
	return 0;
}

function generate_certificate()
{
	# if certificate already exists, return zero
	if [ -f "${HOME}/.sentinelnode/tls.crt" ] && [ -f "${HOME}/.sentinelnode/tls.key" ]
	then
		return 0
	fi
	
	# Generate certificate
	sudo openssl req -new \
	-newkey ec \
	-pkeyopt ec_paramgen_curve:prime256v1 \
	-x509 \
	-sha256 \
	-days 365 \
	-nodes \
	-out ${HOME}/.sentinelnode/tls.crt \
	-subj "/C=NA/ST=NA/L=./O=NA/OU=./CN=." \
	-keyout ${HOME}/.sentinelnode/tls.key || { output_error "Failed to generate certificate."; return 1; }
	
	sudo chown root:root ${HOME}/.sentinelnode/tls.crt && \
	sudo chown root:root ${HOME}/.sentinelnode/tls.key || { output_error "Failed to change ownership of certificate files."; return 1; }
	
	return 0;
}

# Function to install sentinel image
function install_sentinel_container()
{
	# Check if image already downloaded
	if docker image inspect sentinel-dvpn-node &> /dev/null
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
			IMAGE="wajatmaka/sentinel-arm7-debian:latest"
		elif [[ $(arch) == "aarch64"* ]] || [[ $(arch) == "arm64"* ]]
		then
			IMAGE="wajatmaka/sentinel-aarch64-alpine:latest"
		else
			output_error "Unsupported architecture. Please use ARMv7 or ARM64."
			return 1
		fi
	else
		output_error "Unsupported OS. Please use Ubuntu or Raspbian."
		return 1
	fi
	
	output_log "Pulling the Sentinel image: ${IMAGE}"
	
	# Pull the Sentinel image
	docker pull ${IMAGE} || { output_error "Failed to pull the Sentinel image."; return 1; }
	docker tag ${IMAGE} sentinel-dvpn-node || { output_error "Failed to tag the Sentinel image."; return 1; }
	
	return 0;
}

# Function to install Docker if not already installed
function install_docker()
{
	# Check if Docker is installed return 0
	if command -v docker &> /dev/null
	then
		return 0
	fi
	
	# Install dependencies
	sudo apt install -y curl git openssl || { output_error "Failed to install dependencies."; return 1; }
	
	# Download and execute the Docker installation script
	curl -fsSL get.docker.com -o "${HOME}/get-docker.sh" && sudo sh "${HOME}/get-docker.sh" || { output_error "Failed to install Docker."; return 1; }
	
	# Enable and start the Docker service
	sudo systemctl enable --now docker || { output_error "Failed to enable Docker."; return 1; }

	# Add the current user to the Docker group
	sudo usermod -aG docker $(whoami) || { output_error "Failed to add user to Docker group."; return 1; }

	# Re-login the user to apply group changes
	sudo -i -u $(whoami) || { output_error "Failed to re-login user."; return 1; }
	
	# Check if Docker is now installed
	if ! command -v docker &> /dev/null
	then
		output_error "Docker installation failed.";
		return 1
	fi
	
	return 0
}


# Function to check if all dependencies are installed
function check_installation()
{
	# If curl is not installed, return false
	if ! command -v curl &> /dev/null
	then
		return 1
	fi
	
	# If docker is not installed, return false
	if ! command -v docker &> /dev/null
	then
		return 1
	fi
	
	# If sentinel docker image not installed, return false
	if ! docker image inspect sentinel-dvpn-node &> /dev/null
	then
		return 1
	fi
	
	# If sentinel config not generated, return false
	if [ ! -f "${HOME}/.sentinelnode/config.toml" ]
	then
		return 1
	fi
	
	# If wireguard config not generated, return false
	if [ ! -f "${HOME}/.sentinelnode/config/wireguard.toml" ]
	then
		return 1
	fi
	
	# If v2ray config not generated, return false
	if [ ! -f "${HOME}/.sentinelnode/config/v2ray.toml" ]
	then
		return 1
	fi
	
	
}

# Function to display the installation menu
function menu_installation()
{
	if ! whiptail --title "Welcome to Sentinel Installation" --yesno "Welcome to the Sentinel installation process. This installation will be done in multiple steps and you will be guided throughout the process. Do you want to continue with the installation process?" 10 78
	then
		echo "Installation process skipped."
		# Stop script execution
		exit 0
	fi
	
	install_docker || return 1;
	
	install_sentinel_container || return 1;
	
	if [ ! -d "${HOME}/.sentinelnode" ]; then
		sudo mkdir ${HOME}/.sentinelnode || { output_error "Failed to create Sentinel node directory."; return 1; }
	fi
	
	generate_certificate || return 1;
	
	generate_sentinel_config || return 1;
	
	ask_moniker || return 1;
	
	ask_node_type || return 1;
	
	ask_remote_ip || return 1;
	
	refresh_config_files || return 1;
	
	open_firewall || return 1;
	
	initialize_wallet || return 1;
	
	wait_funds || return 1;
	
	# Start the Sentinel node
	start_node || return 1;
	
	# Display message to user
	whiptail --title "Installation Complete" --msgbox "The Sentinel node has been successfully installed and started!\nYou can now access the node dashboard by visiting the following URL:\n\nhttps://${NODE_IP}:${NODE_PORT}/status" 12 100
	
	return 0;
}

# Function to display the configuration menu
function menu_configuration()
{
	whiptail --title "Welcome to Sentinel Configuration" --msgbox "Welcome to the Sentinel configuration process. This configuration will be done in multiple steps and you will be guided throughout the process." 8 78
}

# Main function
function main()
{
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
}
# Call the main function
main
