#!/bin/bash

# Script version
INSTALLER_VERSION="1.0.0"
# Sentinel documentation Url
DOCS_URL="https://docs.sentinel.co/"

# User and home directory
USER_NAME=${SUDO_USER:-$(whoami)}
USER_HOME=$(getent passwd ${USER_NAME} | cut -d: -f6)

# Configuration file access paths
CONFIG_DIR="${USER_HOME}/.sentinelnode"
CONFIG_FILE="${CONFIG_DIR}/config.toml"
CONFIG_WIREGUARD="${CONFIG_DIR}/wireguard.toml"
CONFIG_V2RAY="${CONFIG_DIR}/v2ray.toml"
CONFIG_TLS_CRT="${CONFIG_DIR}/tls.crt"
CONFIG_TLS_KEY="${CONFIG_DIR}/tls.key"

# Configuration variables
CONTAINER_NAME="sentinel-dvpn-node"
FIREWALL="ufw"
NODE_MONIKER=""
NODE_TYPE="wireguard"
NODE_IP="0.0.0.0"
NODE_COUNTRY="NA"
NODE_PORT=16567
NODE_LOCATION="datacenter"
WIREGUARD_PORT=16568
V2RAY_PORT=16568
WALLET_NAME="operator"
MAX_PEERS=250
HANDSHAKE_ENABLE="true"

# Fixed values loaded from api "dvpn-node/configuration" (except for BACKEND)
BACKEND="test"
CHAIN_ID="sentinelhub-2"
RPC_ADDRESSES="https://rpc.sentinel.co:443,https://rpc.sentinel.quokkastake.io:443,https://rpc.trinityvalidator.com:443"
GAS=200000
GAS_ADJUSTMENT=1.05
GAS_PRICE="0.1udvpn"
DATACENTER_GIGABYTE_PRICES="52573ibc/31FEE1A2A9F9C01113F90BD0BBCCE8FD6BBB8585FAF109A2101827DD1D5B95B8,9204ibc/A8C2D23A1E6F95DA4E48BA349667E322BD7A6C996D8A4AAE8BA72E190F3D1477,1180852ibc/B1C0DDB14F25279A2026BC8794E12B259F8BDA546A3C5132CCAEE4431CE36783,122740ibc/ED07A3391A112B175915CD8FAF43A2DA8E4790EDE12566649D0C2F97716B8518,15342624udvpn"
DATACENTER_HOURLY_PRICES="18480ibc/31FEE1A2A9F9C01113F90BD0BBCCE8FD6BBB8585FAF109A2101827DD1D5B95B8,770ibc/A8C2D23A1E6F95DA4E48BA349667E322BD7A6C996D8A4AAE8BA72E190F3D1477,1871892ibc/B1C0DDB14F25279A2026BC8794E12B259F8BDA546A3C5132CCAEE4431CE36783,18897ibc/ED07A3391A112B175915CD8FAF43A2DA8E4790EDE12566649D0C2F97716B8518,4160000udvpn"
RESIDENTIAL_GIGABYTE_PRICES="52573ibc/31FEE1A2A9F9C01113F90BD0BBCCE8FD6BBB8585FAF109A2101827DD1D5B95B8,9204ibc/A8C2D23A1E6F95DA4E48BA349667E322BD7A6C996D8A4AAE8BA72E190F3D1477,1180852ibc/B1C0DDB14F25279A2026BC8794E12B259F8BDA546A3C5132CCAEE4431CE36783,122740ibc/ED07A3391A112B175915CD8FAF43A2DA8E4790EDE12566649D0C2F97716B8518,15342624udvpn"
RESIDENTIAL_HOURLY_PRICES="18480ibc/31FEE1A2A9F9C01113F90BD0BBCCE8FD6BBB8585FAF109A2101827DD1D5B95B8,770ibc/A8C2D23A1E6F95DA4E48BA349667E322BD7A6C996D8A4AAE8BA72E190F3D1477,1871892ibc/B1C0DDB14F25279A2026BC8794E12B259F8BDA546A3C5132CCAEE4431CE36783,18897ibc/ED07A3391A112B175915CD8FAF43A2DA8E4790EDE12566649D0C2F97716B8518,10000000udvpn"

# Dynamic values
INSTALLATION_CHECKS_ENABLED=true
PUBLIC_ADDRESS=""
NODE_ADDRESS=""
WALLET_BALANCE=""
WALLET_BALANCE_AMOUNT=0
WALLET_BALANCE_DENOM="DVPN"
WALLET_PASSPHRASE=""
CERTIFICATE_DATE_CREATION=""
CERTIFICATE_DATE_EXPIRATION=""
CERTIFICATE_ISSUER=""
CERTIFICATE_SUBJECT=""
FIREWALL_PREVIOUS_NODE_PORT=0
FIREWALL_PREVIOUS_WIREGUARD_PORT=0
FIREWALL_PREVIOUS_V2RAY_PORT=0
FIREWALL_PREVIOUS_NODE_TYPE=""

# API URLs
GROWTHDAO_API_BALANCE="https://api.sentinelgrowthdao.com/cosmos/bank/v1beta1/balances/"
FOXINODES_API_CHECK_IP="https://wapi.foxinodes.net/api/v1/sentinel/check-ip"
FOXINODES_API_DVPN_CONFIG="https://wapi.foxinodes.net/api/v1/sentinel/dvpn-node/configuration"
FOXINODES_API_CHECK_PORT="https://wapi.foxinodes.net/api/v1/sentinel/dvpn-node/check-port/"

####################################################################################################
# Configuration functions
####################################################################################################

# Function to load configuration files into variables
function load_config_files()
{
	# Show waiting message
	output_info "Please wait while the configuration files are being loaded..."
	
	# Load config files into variables
	NODE_MONIKER=$(grep "^moniker\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	NODE_TYPE=$(grep "^type\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	NODE_IP=$(grep "^remote_url\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"' | awk -F"/" '{print $3}' | awk -F":" '{print $1}')
	NODE_PORT=$(grep "^listen_on\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"' | awk -F":" '{print $2}')
	CHAIN_ID=$(grep "^id\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	MAX_PEERS=$(grep "^max_peers\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	# RPC_ADDRESSES=$(grep "^rpc_addresses\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	BACKEND=$(grep "^backend\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	WALLET_NAME=$(grep "^from\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	
	# Get handshake enable parameter (check if the section exists and if the parameter exists in the section)
	HANDSHAKE_ENABLE=$(awk '
	BEGIN {FS="="; section_found=0}
	/^\[handshake\]/ {section_found=1; next}
	/^\[.*\]/ && !/^\[handshake\]/ {section_found=0}
	section_found && /enable/ {
		gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2);  # Nettoie les espaces avant et après la valeur
		print $2;  # Affiche uniquement la valeur
		exit;
	}' $CONFIG_FILE)
	
	# Find out if the node is residential or datacenter
	local HOURLY_PRICES=$(grep "^hourly_prices\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	
	# If hourly_prices equal to DATACENTER_HOURLY_PRICES
	if [ "$HOURLY_PRICES" == "$DATACENTER_HOURLY_PRICES" ]
	then
		NODE_LOCATION="datacenter"
	# If hourly_prices is not empty
	elif [ ! -z "$HOURLY_PRICES" ]
	then
		NODE_LOCATION="residential"
	else
		NODE_LOCATION=""
	fi
	
	# If node type is wireguard and wireguard config exists
	if [ "$NODE_TYPE" == "wireguard" ]
	then
		load_wireguard_config
		# Duplicate the value to V2RAY_PORT
		V2RAY_PORT=$WIREGUARD_PORT
	elif [ "$NODE_TYPE" == "v2ray" ]
	then
		load_v2ray_config
		# Duplicate the value to WIREGUARD_PORT
		WIREGUARD_PORT=$V2RAY_PORT
	fi
	
	output_success "Configuration files have been loaded."
	return 0;
}

# Function to load vpn configuration files
function load_vpn_config()
{
	# Load random port for WireGuard or V2Ray
	if [ "$NODE_TYPE" == "wireguard" ]
	then
		load_wireguard_config
	elif [ "$NODE_TYPE" == "v2ray" ]
	then
		load_v2ray_config
	else
		output_error "Invalid node type."
		return 1
	fi
	
	return 0;
}

# Function to load wireguard configuration
function load_wireguard_config()
{
	# If wireguard config exists
	if [ -f "${CONFIG_WIREGUARD}" ]
	then
		# Load from WireGuard configuration
		WIREGUARD_PORT=$(grep "^listen_port\s*=" "${CONFIG_WIREGUARD}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	fi
	
	return 0;
}

# Function to load v2ray configuration
function load_v2ray_config()
{
	# If v2ray config exists
	if [ -f "${CONFIG_V2RAY}" ]
	then
		# Load from V2Ray configuration
		V2RAY_PORT=$(grep "^listen_port\s*=" "${CONFIG_V2RAY}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	fi
	
	return 0;
}

# Function to refresh configuration files
function refresh_config_files()
{
	output_info "Please wait while the configuration files are being refreshed..."
	
	# Update configuration
	sed -i "s/moniker = .*/moniker = \"${NODE_MONIKER}\"/g" ${CONFIG_FILE} || { output_error "Failed to set moniker."; return 1; }
	
	# Update chain_id parameter
	sed -i "s/id = .*/id = \"${CHAIN_ID}\"/g" ${CONFIG_FILE} || { output_error "Failed to set chain ID."; return 1; }
	
	# Update rpc_addresses parameter
	sed -i "s/rpc_addresses = .*/rpc_addresses = \"${RPC_ADDRESSES//\//\\/}\"/g" ${CONFIG_FILE} || { output_error "Failed to set remote RPC."; return 1; }
	
	# Update node type parameter
	sed -i "s/type = .*/type = \"${NODE_TYPE}\"/g" ${CONFIG_FILE} || { output_error "Failed to set node type."; return 1; }
	
	# Update remote_url parameter
	sed -i "s/listen_on = .*/listen_on = \"0\\.0\\.0\\.0:${NODE_PORT}\"/g" ${CONFIG_FILE} || { output_error "Failed to set remote URL."; return 1; }
	
	# Update remote_url parameter
	sed -i "s/remote_url = .*/remote_url = \"https:\/\/${NODE_IP}:${NODE_PORT}\"/g" ${CONFIG_FILE} || { output_error "Failed to set remote URL."; return 1; }
	
	# Update backend parameter
	sed -i "s/backend = .*/backend = \"${BACKEND}\"/g" ${CONFIG_FILE} || { output_error "Failed to set backend."; return 1; }
	
	# Update handshake enable parameter
	sed -i '/^\[handshake\]$/,/^\[/!b; /^\[handshake\]$/,/^\[/ {/^[[:space:]]*enable[[:space:]]*=/s/=.*/= '"${HANDSHAKE_ENABLE}"'/; /^[[:space:]]*\[/b}' "${CONFIG_FILE}"

	# Update max_peers parameter
	sed -i "s/max_peers = .*/max_peers = ${MAX_PEERS}/g" ${CONFIG_FILE} || { output_error "Failed to set max peers."; return 1; }
	
	# Update Gas parameters
	sed -i "s/gas = .*/gas = ${GAS}/g" ${CONFIG_FILE} || { output_error "Failed to set gas."; return 1; }
	
	# Update Gas adjustment parameters
	sed -i "s/gas_adjustment = .*/gas_adjustment = ${GAS_ADJUSTMENT}/g" ${CONFIG_FILE} || { output_error "Failed to set gas adjustment."; return 1; }
	
	# Update Gas price parameters
	sed -i "s/gas_price = .*/gas_price = \"${GAS_PRICE}\"/g" ${CONFIG_FILE} || { output_error "Failed to set gas price."; return 1; }
	
	# Update prices parameters
	if [ "$NODE_LOCATION" == "residential" ]
	then
		# Update gigabyte_prices parameter
		sed -i "s/gigabyte_prices = .*/gigabyte_prices = \"${RESIDENTIAL_GIGABYTE_PRICES//\//\\/}\"/g" ${CONFIG_FILE} || { output_error "Failed to set gigabyte prices."; return 1; }
		
		# Update hourly_prices parameter
		sed -i "s/hourly_prices = .*/hourly_prices = \"${RESIDENTIAL_HOURLY_PRICES//\//\\/}\"/g" ${CONFIG_FILE} || { output_error "Failed to set hourly prices."; return 1; }
	else
		# Update gigabyte_prices parameter
		sed -i "s/gigabyte_prices = .*/gigabyte_prices = \"${DATACENTER_GIGABYTE_PRICES//\//\\/}\"/g" ${CONFIG_FILE} || { output_error "Failed to set gigabyte prices."; return 1; }
		
		# Update hourly_prices parameter
		sed -i "s/hourly_prices = .*/hourly_prices = \"${DATACENTER_HOURLY_PRICES//\//\\/}\"/g" ${CONFIG_FILE} || { output_error "Failed to set hourly prices."; return 1; }
	fi
	
	# Update vpn configuration
	if [ "$NODE_TYPE" == "wireguard" ]
	then
		# Update WireGuard port
		sed -i "s/listen_port = .*/listen_port = ${WIREGUARD_PORT}/g" ${CONFIG_WIREGUARD} || { output_error "Failed to set WireGuard port."; return 1; }
	elif [ "$NODE_TYPE" == "v2ray" ]
	then
		# Update V2Ray port
		sed -i "s/listen_port = .*/listen_port = ${V2RAY_PORT}/g" ${CONFIG_V2RAY} || { output_error "Failed to set V2Ray port."; return 1; }
	fi
	
	output_success "Configuration files have been refreshed."
	return 0;
}

# Load configuration from API
function load_network_configuration()
{
	# Show waiting message
	output_info "Please wait while the network configuration is being retrieved..."
	
	# Retrieve configuration from API
	local CONFIG=$(curl -s ${FOXINODES_API_DVPN_CONFIG})
	
	# If the value is empty, return 1
	if [ -z "$CONFIG" ]
	then
		return 1;
	fi
	
	# Set the values from the API
	CHAIN_ID=$(echo "$CONFIG" | jq -r '.chain_id')
	RPC_ADDRESSES=$(echo "$CONFIG" | jq -r '.rpc_addresses')
	GAS=$(echo "$CONFIG" | jq -r '.gas')
	GAS_ADJUSTMENT=$(echo "$CONFIG" | jq -r '.gas_adjustment')
	GAS_PRICE=$(echo "$CONFIG" | jq -r '.gas_price')
	DATACENTER_GIGABYTE_PRICES=$(echo "$CONFIG" | jq -r '.datacenter.gigabyte_prices')
	DATACENTER_HOURLY_PRICES=$(echo "$CONFIG" | jq -r '.datacenter.hourly_prices')
	RESIDENTIAL_GIGABYTE_PRICES=$(echo "$CONFIG" | jq -r '.residential.gigabyte_prices')
	RESIDENTIAL_HOURLY_PRICES=$(echo "$CONFIG" | jq -r '.residential.hourly_prices')
	
	return 0;
}

# Function to generate node configuration file
function generate_node_config()
{
	# If sentinel config not generated
	if [ ! -f "${CONFIG_FILE}" ]
	then
		# Show waiting message
		output_info "Please wait while the dVPN node configuration is being generated..."
		# Generate Sentinel config
		docker run --rm \
			--volume ${CONFIG_DIR}:/root/.sentinelnode \
			${CONTAINER_NAME} process config init || { output_error "Failed to generate Sentinel configuration."; return 1; }
		output_success "The dVPN node configuration has been generated."
	fi
	
	return 0;
}

# Function to generate vpn configuration
function generate_vpn_config()
{
	# If node type is wireguard
	if [ "$NODE_TYPE" == "wireguard" ]
	then
		# If wireguard config not generated
		if [ ! -f "${CONFIG_WIREGUARD}" ]
		then
			# Show waiting message
			output_info "Please wait while the WireGuard configuration is being generated..."
			# Generate WireGuard config
			docker run --rm \
				--volume ${CONFIG_DIR}:/root/.sentinelnode \
				${CONTAINER_NAME} process wireguard config init || { output_error "Failed to generate WireGuard configuration."; return 1; }
			
			output_success "WireGuard configuration has been generated."
		fi
	# If node type is v2ray
	elif [ "$NODE_TYPE" == "v2ray" ]
	then
		# If v2ray config not generated
		if [ ! -f "${CONFIG_V2RAY}" ]
		then
			# Show waiting message
			output_info "Please wait while the V2Ray configuration is being generated..."
			# Generate V2Ray config
			docker run --rm \
				--volume ${CONFIG_DIR}:/root/.sentinelnode \
				${CONTAINER_NAME} process v2ray config init || { output_error "Failed to generate V2Ray configuration."; return 1; }
			
			output_success "V2Ray configuration has been generated."
		fi
	else
		output_error "Invalid node type."
		return 1
	fi
	
	return 0;
}

# Function to remove vpn configuration files
function remove_vpn_config_files()
{
	# If wireguard config exists, remove it
	if [ -f "${CONFIG_WIREGUARD}" ]
	then
		rm -f ${CONFIG_WIREGUARD}
		output_success "WireGuard configuration has been removed."
	fi
	
	# If v2ray config exists, remove it
	if [ -f "${CONFIG_V2RAY}" ]
	then
		rm -f ${CONFIG_V2RAY}
		output_success "V2Ray configuration has been removed."
	fi
	
	return 0;
}

# Function to remove configuration files
function remove_config_files()
{
	# If configuration files do not exist, return 0
	if [ ! -d "${CONFIG_DIR}" ]
	then
		return 0;
	fi
	
	output_info "Please wait while the configuration files are being removed..."
	# Remove configuration files
	rm -rf ${CONFIG_DIR}
	
	output_success "Configuration files have been removed."
	return 0;
}

####################################################################################################
# Update functions
####################################################################################################

# Function to update the container
function update_container
{
	output_info "Please wait while the dVPN node container is being updated..."
	
	container_remove || return 1;
	container_install || return 1;
	container_start || return 1;
	
	# Display message indicating that the image is up to date
	output_info "The dVPN node container has been updated."
	whiptail --title "Update Complete" --msgbox "dVPN node container is up to date." 8 78
	output_success "dVPN node container has been updated."
	
	return 0;
}

# Function to update the Sentinel network configuration
function update_network
{
	# Ask if user wants to update and overwrite the configuration
	if ! whiptail --title "Configuration Update" --yesno "Would you like to replace your current Sentinel network configuration with the one currently available?" 8 78
	then
		return 0;
	fi
	
	# Load configuration from API
	load_network_configuration || { output_error "Failed to load configuration from API."; return 1; }
	refresh_config_files || return 1;
	
	# Display message indicating that the configuration is up to date
	whiptail --title "Update Complete" --msgbox "Sentinel configuration is up to date." 8 78
	output_success "Sentinel configuration has been updated."
	
	return 0;
}

####################################################################################################
# Utility functions
####################################################################################################

# Function to check if all dependencies are installed
function check_installation()
{
	# Check if installation checks are enabled
	if [ "$INSTALLATION_CHECKS_ENABLED" = false ]
	then
		return 0;
	fi
	
	# Show waiting message
	output_info "Please wait while the installation is being checked..."

	# If docker is not installed, return false
	if ! command -v docker &> /dev/null
	then
		output_info "Docker is not installed."
		return 1
	fi
	
	# If user is not in docker group, return false
	if ! groups "$SUDO_USER" | grep -q "\bdocker\b"
	then
		output_info "User $SUDO_USER is not in the Docker group."
		return 1
	fi
	
	# If sentinel docker image not installed, return false
	if ! docker image inspect ${CONTAINER_NAME} &> /dev/null
	then
		output_info "Sentinel Docker image is not installed."
		return 1
	fi
	
	# If sentinel config not generated, return false
	if [ ! -f "${CONFIG_FILE}" ]
	then
		output_info "Sentinel config is not generated."
		return 1
	fi
	
	# If wireguard or v2ray config not generated, return false
	if [ ! -f "${CONFIG_WIREGUARD}" ] && [ ! -f "${CONFIG_V2RAY}" ]
	then
		output_info "WireGuard and V2Ray config is not generated."
		return 1
	fi
	
	# Load configuration and request passphrase to avoid being stuck
	load_config_files
	ask_wallet_passphrase
	# If wallet does not exist, return false
	if ! wallet_exist
	then
		output_info "Wallet does not exist."
		return 1
	fi
	
	# If container is not initialized, return false
	if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
	then
		output_info "dVPN node container is not initialized."
		return 1
	fi
	
	return 0;
}

# Function to output information messages
function output_info()
{
	local MESSAGE="$1"
	echo -e "\e[34m[INFO]\e[0m ${MESSAGE}"
}

# Function to output success messages
function output_success()
{
	local MESSAGE="$1"
	# Afficher "[SUCCESS]" en vert et le MESSAGE en couleur par défaut
	echo -e "\e[32m[SUCCESS]\e[0m ${MESSAGE}"
}

# Function to output error messages
function output_error()
{
	local ERROR="$1"
	echo -e "\e[31m[ERROR]\e[0m ${ERROR}"
	whiptail --title "Error" --msgbox "${ERROR}" 8 78
}

# Function to check if the OS is Ubuntu (Source: https://github.com/roomit-xyz/sentinel-node/blob/main/sentinel-node.sh)
function os_ubuntu()
{
	# Check if the OS is Ubuntu
	local os_name=$(lsb_release -is)
	if [[ "$os_name" != "Ubuntu" ]]
	then
		return 1
	fi

	local version=$(lsb_release -rs)
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
	local raspbian_check=$(cat /etc/*-release | grep "ID=raspbian" | wc -l)
	local arm_check=$(uname -a | egrep "aarch64|arm64|armv7" | wc -l)
	if [ ${raspbian_check} == 1 ] || [ ${arm_check} == 1 ]
	then
		return 0  
	else
		return 1 
	fi
}


####################################################################################################
# Certificate functions
####################################################################################################

# Function to configure network settings
function certificate_generate()
{
	# If certificate already exists, return zero
	if [ -f "${CONFIG_TLS_CRT}" ] && [ -f "${CONFIG_TLS_KEY}" ]
	then
		return 0
	fi
	
	# If node country is not set, get public IP
	if [ "$NODE_COUNTRY" = "NA" ] || [ -z "$NODE_COUNTRY" ];
	then
		network_remote_addr || { output_error "Failed to get country of the node."; }
	fi
	
	
	# Generate certificate
	openssl req -new \
	-newkey ec \
	-pkeyopt ec_paramgen_curve:prime256v1 \
	-x509 \
	-sha256 \
	-days 365 \
	-nodes \
	-out ${CONFIG_TLS_CRT} \
	-subj "/C=${NODE_COUNTRY}/ST=NA/L=./O=NA/OU=./CN=." \
	-keyout ${CONFIG_TLS_KEY} > /dev/null 2>&1 || { output_error "Failed to generate certificate."; return 1; }
	
	chown root:root ${CONFIG_TLS_CRT} > /dev/null 2>&1 && \
	chown root:root ${CONFIG_TLS_KEY} > /dev/null 2>&1 || { output_error "Failed to change ownership of certificate files."; return 1; }
	
	output_success "Certificate files have been generated."
	return 0;
}

# Function to check if the certificate exists
function certificate_info()
{
	# Check if certificate files exist
	if [ ! -f "${CONFIG_TLS_CRT}" ] || [ ! -f "${CONFIG_TLS_KEY}" ]
	then
		output_info "Certificate or key file not found."
		return 1
	fi
	
	# Read certificate information
	local CERTIFICATE=$(openssl x509 -in "${CONFIG_TLS_CRT}" -text)
	if [ -z "$CERTIFICATE" ]
	then
		output_info "Failed to read certificate."
		return 1
	fi
	
	# Parse the certificate information
	CERTIFICATE_DATE_CREATION=$(echo "$CERTIFICATE" | grep -E "Not Before *:" | cut -d : -f 2- | sed 's/^ *//;s/ *$//')
	CERTIFICATE_DATE_EXPIRATION=$(echo "$CERTIFICATE" | grep -E "Not After *:" | cut -d : -f 2- | sed 's/^ *//;s/ *$//')
	CERTIFICATE_ISSUER=$(echo "$CERTIFICATE" | grep "Issuer:" | cut -d : -f 2- | sed 's/^ *//;s/ *$//;s/ *//g')
	CERTIFICATE_SUBJECT=$(echo "$CERTIFICATE" | grep "Subject:" | cut -d : -f 2- | sed 's/^ *//;s/ *$//;s/ *//g')

	return 0
}

# Function to remove certificate files
function certificate_remove()
{
	# If certificate files do not exist, return 0
	if [ ! -f "${CONFIG_TLS_CRT}" ] && [ ! -f "${CONFIG_TLS_KEY}" ]
	then
		return 0;
	fi
	
	# Remove certificate files
	rm -f ${CONFIG_TLS_CRT}
	rm -f ${CONFIG_TLS_KEY}
	
	output_info "Certificate files have been removed."
	return 0;
}

# Function to renew the certificate
function certificate_renew()
{
	# Remove the existing certificate
	certificate_remove || return 1;
	
	# Generate a new certificate
	certificate_generate || return 1;
	
	return 0;
}

####################################################################################################
# Network functions
####################################################################################################

# Function to get the public IP address
function network_remote_addr()
{
	# Show waiting message
	output_info "Please wait while the public IP is being retrieved..."
	# Retrieve the current public IP using wget and sed
	local VALUE=$(curl -s $FOXINODES_API_CHECK_IP || echo "")
	
	# Reset values
	NODE_IP="0.0.0.0"
	NODE_COUNTRY="NA"
	
	# If VALUE is empty, try with fallback
	if [ -z "$VALUE" ]
	then
		# Fallback to checkip.dyndns.org
		VALUE=$(wget -q -O - checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
		# If IP is not empty
		if [ ! -z "$VALUE" ]
		then
			# Set the IP address
			NODE_IP=$VALUE
		fi
	else
		# Parse the JSON response to extract the values
		NODE_IP=$(echo "$VALUE" | jq -r '.ip')
		NODE_COUNTRY=$(echo "$VALUE" | jq -r '.iso_code')
	fi
	
	return 0;
}

# Function to check if the port is open
function network_check_port()
{
	# If node address is empty, return error
	if [ -z "$NODE_ADDRESS" ]
	then
		output_error "Node address is empty, please check your wallet configuration before proceeding."
		return 1
	fi
	
	local MESSAGE=""
	local RESPONSE=""
	
	while true
	do
		# Show waiting message
		output_info "Please wait while $NODE_PORT is checked to open on $NODE_IP..."
		
		# Reset values (empty message say that the port is open)
		MESSAGE=""
		# Request GET to Foxinodes API
		RESPONSE=$(curl -s "${FOXINODES_API_CHECK_PORT}${NODE_IP}:${NODE_PORT}")
		
		# If the request failed, return error
		if [ $? -ne 0 ]
		then
			MESSAGE="Error requesting Foxinodes API, please try again later by executing the following command: bash dvpn-node-manager.sh check-port"
		fi
		
		# Parse JSON response
		local RQ_ERROR=$(echo "$RESPONSE" | jq -r '.error')
		local RQ_NODE_SUCCESS=$(echo "$RESPONSE" | jq -r '.node.success')
		local RQ_NODE_ADDRESS=$(echo "$RESPONSE" | jq -r '.node.result.address')
		
		# Handle case where attribute is not available
		if [ -z "$RQ_ERROR" ] || [ -z "$RQ_NODE_SUCCESS" ] || [ -z "$RQ_NODE_ADDRESS" ]
		then
			MESSAGE="Error parsing JSON response. The API is down or this script is outdated."
		# If the success is not true, return 1
		elif [ "$RQ_ERROR" == "true" ]
		then
			# If message is not empty, display it
			local RQ_MESSAGE=$(echo "$RESPONSE" | jq -r '.message')
			if [ ! -z "$RQ_MESSAGE" ]
			then
				MESSAGE="$RQ_MESSAGE"
			else
				MESSAGE="An unknown error occurred while checking the port."
			fi
		# Check if the node address is the same as the one we are checking
		elif [ "$RQ_NODE_ADDRESS" != "$NODE_ADDRESS" ]
		then
			MESSAGE="Node address '$RQ_NODE_ADDRESS' is different from the one we are checking '$NODE_ADDRESS'"
		fi
		
		# If MESSAGE is empty, it means port is open and there are no errors
		if [ -z "$MESSAGE" ]
		then
			break
		else
			# Display error message and ask if user wants to retry
			if ! whiptail --title "Error" --yes-button "Retry" --no-button "Quit" \
				--yesno "${MESSAGE}\n\nDo you want to retry?" 10 60
			then
				return 1
			fi
		fi
	done
	
	return 0;
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
		if ! groups "$SUDO_USER" | grep -q "\bdocker\b"
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
	apt install -y git || { output_error "Failed to install dependencies."; return 1; }
	
	# Download and execute the Docker installation script
	set -o pipefail
	curl -fsSL get.docker.com | sh || { output_error "Failed to install Docker."; return 1; }
	
	# Enable and start the Docker service
	systemctl enable --now docker || { output_error "Failed to enable Docker."; return 1; }
	
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
	if ! groups "$SUDO_USER" | grep -q "\bdocker\b"
	then
		# Add the user to the docker group
		usermod -aG docker ${USER_NAME} || { output_error "Failed to add user to docker group."; return 1; }
		output_info "User added to docker group."
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
	
	output_success "Sentinel image has been installed successfully."
	return 0;
}

# Function to start the Docker container
function container_start()
{
	# Show waiting message
	output_info "Please wait while the dVPN node container is being started..."
	
	# If container is already created, check if it is running
	if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
	then
		# Check if the container is not running
		if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
		then
			# Container is not running, attempt to start it
			docker start ${CONTAINER_NAME} > /dev/null 2>&1 || { output_error "Failed to start the dVPN node container."; return 1; }
			output_success "dVPN node container has been started successfully."
		fi
		return 0
	fi
	
	# If node type is wireguard
	if [ "$NODE_TYPE" == "wireguard" ]
	then
		# If passphrase is required
		if [ "$BACKEND" == "file" ]
		then
			# Start WireGuard node
			nohup bash -c "echo '${WALLET_PASSPHRASE}' | docker run --rm \
				--interactive \
				--name ${CONTAINER_NAME} \
				--volume ${CONFIG_DIR}:/root/.sentinelnode \
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
				${CONTAINER_NAME} process start" > /dev/null 2>&1 &
			disown
			# Wait for 5 seconds
			sleep 5
		else
			# Start WireGuard node
			docker run -d \
				--name ${CONTAINER_NAME} \
				--restart unless-stopped \
				--volume ${CONFIG_DIR}:/root/.sentinelnode \
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
				${CONTAINER_NAME} process start > /dev/null 2>&1 || { output_error "Failed to start WireGuard node."; return 1; }
		fi
	elif [ "$NODE_TYPE" == "v2ray" ]
	then
		# If passphrase is required
		if [ "$BACKEND" == "file" ]
		then
			# Start V2Ray node
			nohup bash -c "echo '${WALLET_PASSPHRASE}' | docker run --rm \
				--interactive \
				--name ${CONTAINER_NAME} \
				--volume "${CONFIG_DIR}:/root/.sentinelnode" \
				--publish ${NODE_PORT}:${NODE_PORT}/tcp \
				--publish ${V2RAY_PORT}:${V2RAY_PORT}/tcp \
				${CONTAINER_NAME} process start" > /dev/null 2>&1 &
			disown
			# Wait for 5 seconds
			sleep 5
		else
			# Start V2Ray node
			docker run -d \
				--name ${CONTAINER_NAME} \
				--restart unless-stopped \
				--volume "${CONFIG_DIR}:/root/.sentinelnode" \
				--publish ${NODE_PORT}:${NODE_PORT}/tcp \
				--publish ${V2RAY_PORT}:${V2RAY_PORT}/tcp \
				${CONTAINER_NAME} process start > /dev/null 2>&1 || { output_error "Failed to start V2Ray node."; return 1; }
		fi
	else
		output_error "Invalid node type."
		return 1
	fi
	
	output_success "dVPN node container has been started successfully."
	return 0;
}

# Function to stop the Docker container
function container_stop()
{
	output_info "Please wait while the dVPN node container is being stopped..."
	docker stop ${CONTAINER_NAME} > /dev/null 2>&1 || { output_error "Failed to stop the dVPN node container."; return 1; }
	output_success "dVPN node container has been stopped successfully."
	return 0;
}

# Function to restart the Docker container
function container_restart()
{
	output_info "Please wait while the dVPN node container is being restarted..."
	docker restart ${CONTAINER_NAME} > /dev/null 2>&1 || { output_error "Failed to restart the dVPN node container."; return 1; }
	output_success "dVPN node container has been restarted successfully."
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

# Function to remove the Docker container
function container_remove()
{
	# If container does not exist, return 0
	if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
	then
		return 0
	fi
	
	# Stop the container
	container_stop
	
	# Remove the container
	output_info "Please wait while the dVPN node container is being removed..."
	docker rm --force ${CONTAINER_NAME} > /dev/null 2>&1 || { output_error "Failed to remove the dVPN node container."; return 1; }
	output_success "dVPN node container has been removed successfully."
	
	return 0;
}

# Function to display the container logs
function container_logs()
{
	# Show waiting message
	output_info "Please wait while the dVPN node container logs are being retrieved..."
	# Display message indicating that the container logs are being retrieved
	output_info "Press 'Ctrl + C' to exit the logs."
	
	# Wait for 2 seconds
	sleep 2
	# Retrieve the container logs
	docker logs -f -n 100 ${CONTAINER_NAME} || { output_error "Failed to retrieve the dVPN node container logs."; return 1; }
	
	return 0;
}

####################################################################################################
# Wallet functions
####################################################################################################

function wallet_initialization()
{
	# Check if wallet exists
	if docker run --rm --interactive --tty --volume ${CONFIG_DIR}:/root/.sentinelnode ${CONTAINER_NAME} process keys list | grep -q "sentnode"
	then
		# Ask user if they want to delete the existing wallet
		if whiptail --title "Wallet Exists" --yesno "A wallet already exists. Do you want to delete the existing wallet and continue?" 8 78
		then
			# Delete existing wallet
			wallet_remove
		else
			output_info "Wallet already exists."
			return 0;
		fi
	else
		output_info "No wallet found."
	fi
	
	# Ask if user wants to restore wallet
	if whiptail --title "Wallet Initialization Confirmation" \
		--defaultno --yesno \
		"Do you want to restore an existing Sentinel wallet? Please note that this wallet should be dedicated to this node and not used with any other nodes." 8 78
	then
		while true
		do
			# Ask for mnemonic and store un MNEMONIC variable
			MNEMONIC=$(whiptail --inputbox "Please enter your wallet's mnemonic:" 8 78 --title "Wallet Mnemonic" 3>&1 1>&2 2>&3) || { output_error "Failed to get mnemonic."; return 1; }
			# If mnemonic is not empty, break loop
			if [ ! -z "$MNEMONIC" ]
			then
				break
			fi
		done
		
		# Remove end of line and spaces at the beginning and end
		MNEMONIC=$(echo "$MNEMONIC" | tr -d '\r' | xargs)
		
		# Restore wallet
		output_info "Restoring wallet, please wait..."
		
		# If passphrase is required
		if [ "$BACKEND" == "file" ]
		then
			echo -e "${MNEMONIC}\n${WALLET_PASSPHRASE}\n${WALLET_PASSPHRASE}" | docker run --rm \
				--interactive \
				--volume ${CONFIG_DIR}:/root/.sentinelnode \
				${CONTAINER_NAME} process keys add --recover > /dev/null 2>&1 || { output_error "Failed to restore wallet."; return 1; }
		else
			echo "$MNEMONIC" | docker run --rm \
				--interactive \
				--volume ${CONFIG_DIR}:/root/.sentinelnode \
				${CONTAINER_NAME} process keys add --recover > /dev/null 2>&1 || { output_error "Failed to restore wallet."; return 1; }
		fi
		output_success "Wallet restored successfully."
	else
		# Create new wallet
		output_info "Creating new wallet, please wait..."
		
		# If passphrase is required
		if [ "$BACKEND" == "file" ]
		then
			OUTPUT=$( (echo "${WALLET_PASSPHRASE}"; echo "${WALLET_PASSPHRASE}") | docker run --rm \
						--interactive \
						--volume ${CONFIG_DIR}:/root/.sentinelnode \
						${CONTAINER_NAME} process keys add 2>&1 )
		else
			OUTPUT=$(docker run --rm \
						--interactive \
						--tty \
						--volume ${CONFIG_DIR}:/root/.sentinelnode \
						${CONTAINER_NAME} process keys add)
		fi
		
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
		
		# Calculate the maximum width for each column
		declare -a max_widths=(0 0 0 0)
		for i in {0..3}; do
			max_widths[$i]=$(echo "$MNEMONIC" | tr -s ' ' '\n' | awk -v pos="$((i+1))" '(NR-1) % 4 == pos-1' | awk '{print length}' | sort -nr | head -n1)
		done
		# After calculating the maximum width, add 3 to each column
		for i in {0..3}; do
			max_widths[$i]=$((max_widths[$i] + 3))
		done
		
		# Découpage intelligent en groupes de mots
		formatted_mnemonic=$(echo "$MNEMONIC" | tr -s ' ' '\n' | awk -v mw1="${max_widths[0]}" -v mw2="${max_widths[1]}" -v mw3="${max_widths[2]}" -v mw4="${max_widths[3]}" '{
			if (NR % 4 == 1) printf "%2d. %-*s ", NR, mw1, $0;
			if (NR % 4 == 2) printf "%2d. %-*s ", NR, mw2, $0;
			if (NR % 4 == 3) printf "%2d. %-*s ", NR, mw3, $0;
			if (NR % 4 == 0) printf "%2d. %-*s\n", NR, mw4, $0;
		} END {
			if (NR % 4 != 0) print "";
		}')
		
		# Display the mnemonic
		MESSAGE="    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
		MESSAGE+="    !! Please securely save the 24-word mnemonic phrase provided. !!\n"
		MESSAGE+="    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
		MESSAGE+="\n"
		MESSAGE+="It's essential for recovering your wallet if you lose access or forget your password. Loss of this phrase means permanent loss of access to your funds and dVPN node. Store it privately and in multiple safe places.\n\n"
		MESSAGE+="Mnemonic:\n\n${formatted_mnemonic}"
		whiptail --title "Wallet Mnemonic" --msgbox "$MESSAGE" 22 80
		
		output_success "Wallet created successfully."
	fi
	
	return 0;
}

# Function to check if wallet exists
function wallet_exist()
{
	# Check if a wallet with the specified name exists
	local wallet_list_output=""
	
	# If passphrase is required
	if [ "$BACKEND" == "file" ]
	then
		wallet_list_output=$(echo "${WALLET_PASSPHRASE}" | docker run --rm \
			--interactive \
			--volume "${CONFIG_DIR}:/root/.sentinelnode" \
			"${CONTAINER_NAME}" process keys list)
	else
		wallet_list_output=$(docker run --rm \
			--interactive \
			--tty \
			--volume "${CONFIG_DIR}:/root/.sentinelnode" \
			"${CONTAINER_NAME}" process keys list)
	fi
	# Use grep to check if the wallet name is in the list
	if echo "$wallet_list_output" | grep -q "$WALLET_NAME"
	then
		return 0
	else
		return 1
	fi
}

# Function to remove the wallet
function wallet_remove()
{
	# If wallet does not exist, return 0
	if wallet_exist
	then
		return 0;
	fi
	
	# If passphrase is required
	if [ "$BACKEND" == "file" ]
	then
		echo "${WALLET_PASSPHRASE}" | docker run --rm \
			--interactive \
			--volume ${CONFIG_DIR}:/root/.sentinelnode \
			${CONTAINER_NAME} process keys delete $WALLET_NAME > /dev/null 2>&1 || { output_error "Failed to delete wallet."; return 1; }
	else
		docker run --rm \
			--interactive \
			--tty \
			--volume ${CONFIG_DIR}:/root/.sentinelnode \
			${CONTAINER_NAME} process keys delete $WALLET_NAME > /dev/null 2>&1 || { output_error "Failed to delete wallet."; return 1; }
	fi
	output_success "Wallet has been removed successfully."
	return 0;
}

# Function to get the public and node addresses of the wallet
function wallet_addresses()
{
	# If PUBLIC_ADDRESS and NODE_ADDRESS are not empty, return 0
	if [ ! -z "$PUBLIC_ADDRESS" ] && [ ! -z "$NODE_ADDRESS" ]
	then
		return 0;
	fi

	# Show waiting message
	output_info "Please wait while the wallet addresses are being retrieved..."

	# Execute Docker command once and store output
	local WALLET_INFO=""
	
	# If passphrase is required
	if [ "$BACKEND" == "file" ]
	then
		WALLET_INFO=$(echo "${WALLET_PASSPHRASE}" | docker run --rm \
			--interactive \
			--volume "${CONFIG_DIR}:/root/.sentinelnode" \
			"${CONTAINER_NAME}" process keys show | awk -v name="$WALLET_NAME" '$1 == name')
	else
		WALLET_INFO=$(docker run --rm \
			--interactive \
			--tty \
			--volume "${CONFIG_DIR}:/root/.sentinelnode" \
			"${CONTAINER_NAME}" process keys show | awk -v name="$WALLET_NAME" '$1 == name')
	fi
	# Extract public and node addresses from the output
	PUBLIC_ADDRESS=$(echo "$WALLET_INFO" | awk '{print $3}')
	NODE_ADDRESS=$(echo "$WALLET_INFO" | awk '{print $2}')
	
	# Remove end of line
	PUBLIC_ADDRESS=$(echo "$PUBLIC_ADDRESS" | tr -d '\r')
	NODE_ADDRESS=$(echo "$NODE_ADDRESS" | tr -d '\r')
	
	output_success "Wallet addresses have been retrieved successfully."
	return 0;
}

# Function to get wallet balance
function wallet_balance()
{
	# Show waiting message
	output_info "Please wait while the balance of ${PUBLIC_ADDRESS} is being retrieved..."
	
	# Get wallet balance from remote API
	local API_RESPONSE=$(curl -s "${GROWTHDAO_API_BALANCE}${PUBLIC_ADDRESS}")
	
	# Reset values
	WALLET_BALANCE="0 DVPN"
	WALLET_BALANCE_AMOUNT=0
	WALLET_BALANCE_DENOM="DVPN"
	
	# If the value is empty, return 1
	if [ -z "$API_RESPONSE" ]
	then
		output_info "API response is empty."
		return 1;
	fi
	
	# Set the value and extract the amount and denom
	local DVPN_OBJECT=$(echo "$API_RESPONSE" | jq -r '.balances[] | select(.denom == "udvpn")')
	# If the value is not empty then extract the amount
	if [ ! -z "$DVPN_OBJECT" ]
	then
		# Set the values
		WALLET_BALANCE_AMOUNT=$(echo "$DVPN_OBJECT" | jq -r '.amount | tonumber / 1000000')
		WALLET_BALANCE="${WALLET_BALANCE_AMOUNT} ${WALLET_BALANCE_DENOM}"
	fi
	
	output_success "Wallet balance has been retrieved successfully."
	return 0;
}


####################################################################################################
# Firewall functions
####################################################################################################

# Function to open the firewall
function firewall_configure()
{
	# Check if UFW is not installed
	if ! command -v ufw &> /dev/null
	then
		# Install UFW
		output_info "Installing UFW, please wait..."
		apt install -y ufw || { output_error "Failed to install UFW."; return 1; }
		
		# Find SSH Port
		local SSH_PORT=$(sudo ss -plntu | grep sshd | awk '{print $5}' | sed -E 's/.*:(.*)/\1/' | uniq)
		# If SSH port is empty
		if [ -z "$SSH_PORT" ]
		then
			SSH_PORT=22
		fi
		# Allow SSH port
		if ! ufw status | grep -q "${SSH_PORT}/tcp"
		then
			output_info "Allowing SSH port ${SSH_PORT} in UFW"
			ufw allow ${SSH_PORT}/tcp > /dev/null 2>&1 || { output_error "Failed to allow SSH port."; return 1; }
		fi
	fi
	
	# If UFW is not enabled
	if ! ufw status | grep -q "Status: active"
	then
		# Enable UFW
		output_info "Enabling UFW, please wait..."
		echo "y" | ufw enable > /dev/null 2>&1 || { output_error "Failed to enable UFW."; return 1; }
	fi
	
	# If previous node port is not empty and different from 0
	if [ ! -z "$FIREWALL_PREVIOUS_NODE_PORT" ] && [ "$FIREWALL_PREVIOUS_NODE_PORT" -ne 0 ]
	then
		firewall_delete_port $FIREWALL_PREVIOUS_NODE_PORT "tcp" || { output_error "Failed to delete previous node port."; return 1; }
		FIREWALL_PREVIOUS_NODE_PORT=0;
	fi
	
	# If node type is WireGuard and WireGuard port is not empty
	if [ "$NODE_TYPE" = "wireguard" ] && [ ! -z "$WIREGUARD_PORT" ]
	then
		firewall_delete_port $FIREWALL_PREVIOUS_WIREGUARD_PORT "udp" || { output_error "Failed to delete previous WireGuard port."; return 1; }
		FIREWALL_PREVIOUS_WIREGUARD_PORT=0;
	fi
	
	# If node type is V2Ray and V2Ray port is not empty
	if [ "$NODE_TYPE" = "v2ray" ] && [ ! -z "$V2RAY_PORT" ]
	then
		firewall_delete_port $FIREWALL_PREVIOUS_V2RAY_PORT "tcp" || { output_error "Failed to delete previous V2Ray port."; return 1; }
		FIREWALL_PREVIOUS_V2RAY_PORT=0;
	fi
	
	# If previous node type is not empty and types are different
	if [ ! -z "$FIREWALL_PREVIOUS_NODE_TYPE" ] && [ "$FIREWALL_PREVIOUS_NODE_TYPE" != "$NODE_TYPE" ]
	then
		# If previous node type is WireGuard
		if [ "$FIREWALL_PREVIOUS_NODE_TYPE" = "wireguard" ]
		then
			firewall_delete_port $WIREGUARD_PORT "udp" || { output_error "Failed to delete previous WireGuard port."; return 1; }
			FIREWALL_PREVIOUS_WIREGUARD_PORT=0;
		# If previous node type is V2Ray
		elif [ "$FIREWALL_PREVIOUS_NODE_TYPE" = "v2ray" ]
		then
			firewall_delete_port $V2RAY_PORT "tcp" || { output_error "Failed to delete previous V2Ray port."; return 1; }
			FIREWALL_PREVIOUS_V2RAY_PORT=0;
		fi
	fi
	# Delete the previous node type value as the information is no longer useful
	FIREWALL_PREVIOUS_NODE_TYPE="";
	
	# Add ports to firewall
	firewall_allow_port $NODE_PORT "tcp" || { output_error "Failed to allow node port."; return 1; }
	if [ "$NODE_TYPE" = "wireguard" ]
	then
		firewall_allow_port $WIREGUARD_PORT "udp" || { output_error "Failed to allow WireGuard."; return 1; }
	elif [ "$NODE_TYPE" = "v2ray" ]
	then
		firewall_allow_port $V2RAY_PORT "tcp" || { output_error "Failed to allow V2Ray."; return 1; }
	fi
	
	# Reload UFW
	output_info "Reloading UFW, please wait..."
	ufw reload > /dev/null 2>&1 || { output_error "Failed to reload UFW."; return 1; }
	
	return 0;
}

# Function to delete all firewall rules
function firewall_reset()
{
	# If UFW is not installed, return 0
	if ! command -v ufw &> /dev/null
	then
		return 0;
	fi
	
	# Delete all firewall rules
	firewall_delete_port $NODE_PORT "tcp" || { output_error "Failed to delete node port."; return 1; }
	if [ "$NODE_TYPE" = "wireguard" ]
	then
		firewall_delete_port $WIREGUARD_PORT "udp" || { output_error "Failed to delete WireGuard."; return 1; }
	elif [ "$NODE_TYPE" = "v2ray" ]
	then
		firewall_delete_port $V2RAY_PORT "tcp" || { output_error "Failed to delete V2Ray."; return 1; }
	fi
	
	return 0;
}

# Function to allow firewall port
function firewall_allow_port()
{
	local PORT=$1
	local PROTOCOL=$2
	# If port is not empty and is a number between 1024 and 65535
	if [ ! -z "$PORT" ] && [[ "$PORT" =~ ^[0-9]+$ ]] && [[ "$PORT" -ge 1024 ]] && [[ "$PORT" -le 65535 ]]
	then
		# Allow port to firewall if not already allowed
		if ! ufw status | grep -q "${PORT}/${PROTOCOL}"
		then
			ufw allow ${PORT}/${PROTOCOL} > /dev/null 2>&1 || return 1;
			output_success "Allowing port ${PORT}/${PROTOCOL} in UFW"
		fi
	fi
	
	return 0;
}

# Function to delete firewall port
function firewall_delete_port()
{
	local PORT=$1
	local PROTOCOL=$2
	# If port is not empty and is a number between 1024 and 65535
	if [ ! -z "$PORT" ] && [[ "$PORT" =~ ^[0-9]+$ ]] && [[ "$PORT" -ge 1024 ]] && [[ "$PORT" -le 65535 ]]
	then
		# Delete port from firewall if the rule exists
		if ufw status | grep -q "${PORT}/${PROTOCOL}"
		then
			ufw delete allow ${PORT}/${PROTOCOL} > /dev/null 2>&1 || return 1;
			output_success "Deleting port ${PORT}/${PROTOCOL} in UFW"
		fi
	fi
	
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
		network_remote_addr || { output_error "Failed to get public IP, please check your network configuration."; return 1; }
	fi
	
	# Ask for remote IP
	local VALUE=$(whiptail --inputbox "Please enter your node's public IP address:" 8 78 "$NODE_IP" --title "Node IP" 3>&1 1>&2 2>&3) || return 1;
	
	# Check if the user pressed Cancel
	if [ $? -ne 0 ]
	then
		return 1
	fi

	# Check if the user entered a value
	if [ -z "$VALUE" ]
	then
		return 2
	fi
	
	# Set value received from whiptail to NODE_IP
	NODE_IP=$VALUE
	return 0;
}

# Function to ask for node port
function ask_node_port()
{
	local VALUE=""
	
	while true
	do
		# Ask for node port
		VALUE=$(whiptail --inputbox "Please enter the port number you want to use for the node:" 8 78 "$NODE_PORT" \
			--title "Node Port" 3>&1 1>&2 2>&3) || { echo "Failed to get node port" && return 1; }
		# If value is not empty and is integer (between 1024 and 65535) and different of $WIREGUARD_PORT or $V2RAY_PORT
		if [[ ! -z "$VALUE" ]] && [[ "$VALUE" =~ ^[0-9]+$ ]] && \
			[[ "$VALUE" -ge 1024 ]] && [[ "$VALUE" -le 65535 ]] && \
			[[ "$VALUE" -ne "$WIREGUARD_PORT" ]] && [[ "$VALUE" -ne "$V2RAY_PORT" ]]
		then
			break
		fi
	done
	
	# If VALUE is different of $NODE_PORT
	if [ "$VALUE" -ne "$NODE_PORT" ]
	then
		# Store the value in FIREWALL_PREVIOUS_NODE_PORT to delete it from the firewall
		FIREWALL_PREVIOUS_NODE_PORT=$NODE_PORT
		# Set value received from whiptail to NODE_PORT
		NODE_PORT=$VALUE
	else
		FIREWALL_PREVIOUS_NODE_PORT=0
	fi
	
	return 0;
}

# Function to request the correct vpn port
function ask_vpn_port()
{
	if [ "$NODE_TYPE" = "wireguard" ]
	then
		ask_wireguard_port
	elif [ "$NODE_TYPE" = "v2ray" ]
	then
		ask_v2ray_port
	fi
}

# Function to ask for WireGuard port
function ask_wireguard_port()
{
	local VALUE=""
	
	while true
	do
		# Ask for node port
		VALUE=$(whiptail --inputbox "Please enter the port number you want to use for WireGuard:" 8 78 "$WIREGUARD_PORT" \
			--title "WireGuard Port" 3>&1 1>&2 2>&3) || { echo "Failed to get node port" && return 1; }
		# If value is not empty and is integer (between 1024 and 65535) and different of $NODE_PORT
		if [[ ! -z "$VALUE" ]] && [[ "$VALUE" =~ ^[0-9]+$ ]] && \
			[[ "$VALUE" -ge 1024 ]] && [[ "$VALUE" -le 65535 ]] && \
			[[ "$VALUE" -ne "$NODE_PORT" ]]
		then
			break
		fi
	done
	
	# If VALUE is different of $WIREGUARD_PORT
	if [ "$VALUE" -ne "$WIREGUARD_PORT" ]
	then
		# Store the value in FIREWALL_PREVIOUS_WIREGUARD_PORT to delete it from the firewall
		FIREWALL_PREVIOUS_WIREGUARD_PORT=$WIREGUARD_PORT
		# Set value received from whiptail to WIREGUARD_PORT
		WIREGUARD_PORT=$VALUE
	else
		FIREWALL_PREVIOUS_WIREGUARD_PORT=0
	fi
	
	return 0;
}

# Function to ask for V2Ray port
function ask_v2ray_port()
{
	local VALUE=""
	
	while true
	do
		# Ask for node port
		VALUE=$(whiptail --inputbox "Please enter the port number you want to use for V2Ray:" 8 78 "$V2RAY_PORT" \
			--title "V2Ray Port" 3>&1 1>&2 2>&3) || { echo "Failed to get node port" && return 1; }
		# If value is not empty and is integer and is different of $NODE_PORT
		if [[ ! -z "$VALUE" ]] && [[ "$VALUE" =~ ^[0-9]+$ ]] && [[ "$VALUE" -ne "$NODE_PORT" ]]
		then
			break
		fi
	done
	
	# If VALUE is different of $V2RAY_PORT
	if [ "$VALUE" -ne "$V2RAY_PORT" ]
	then
		# Store the value in FIREWALL_PREVIOUS_V2RAY_PORT to delete it from the firewall
		FIREWALL_PREVIOUS_V2RAY_PORT=$V2RAY_PORT
		# Set value received from whiptail to V2RAY_PORT
		V2RAY_PORT=$VALUE
	else
		FIREWALL_PREVIOUS_V2RAY_PORT=0
	fi
	
	return 0;
}

# Function to ask for configure firewall
function ask_firewall_configure()
{
	local MESSAGE=$1
	# Ask if user wants to configure the firewall
	if ! whiptail --title "Firewall Configuration" --yesno "$MESSAGE" 8 78
	then
		return 0;
	fi
	
	firewall_configure || return 1;
	
	return 0;
}

# Function to ask for node location
function ask_node_location()
{
	# Set initial state based on current $NODE_LOCATION
	local datacenter_state="OFF"
	local residential_state="OFF"

	if [ "$NODE_LOCATION" == "datacenter" ]
	then
		datacenter_state="ON"
	elif [ "$NODE_LOCATION" == "residential" ]
	then
		residential_state="ON"
	else
		residential_state="ON"
	fi
	
	# Ask for node location using whiptail
	local VALUE=$(whiptail --title "Node Location" --radiolist "Please select the type of validation node you want to run:" 15 78 2 \
		"datacenter" "Your node is physically located in a datacenter" $datacenter_state \
		"residential" "Your node is physically in a house" $residential_state 3>&1 1>&2 2>&3) || return 1;
	
	# Check if the user cancelled the dialog
	if [ -z "$VALUE" ]
	then
		return 1
	fi
	
	# Set value received from whiptail to NODE_LOCATION
	NODE_LOCATION=$VALUE
	return 0;
}

# Function to ask for node type
function ask_node_type()
{
	# Set initial state based on current $NODE_TYPE
	local wireguard_state="OFF"
	local v2ray_state="OFF"

	if [ "$NODE_TYPE" == "wireguard" ]
	then
		wireguard_state="ON"
	elif [ "$NODE_TYPE" == "v2ray" ]
	then
		v2ray_state="ON"
	else
		wireguard_state="ON"
	fi

	# Ask for node type using whiptail
	local VALUE=$(whiptail --title "Node Type" --radiolist "Please select the type of node you want to run:" 15 78 2 \
		"wireguard" "WireGuard" $wireguard_state \
		"v2ray" "V2Ray" $v2ray_state 3>&1 1>&2 2>&3)
	
	# Check if the user pressed Cancel
	if [ -z "$VALUE" ]
	then
		return 1
	fi
	
	# Remember previous node type to update firewall configuration
	FIREWALL_PREVIOUS_NODE_TYPE=$NODE_TYPE
	# Set value received from whiptail to NODE_TYPE
	NODE_TYPE=$VALUE

	# If node type is V2Ray
	if [ "$NODE_TYPE" == "v2ray" ];
	then
		# Force handshake to be disabled for V2Ray
		HANDSHAKE_ENABLE="false"
	else
		# Force handshake to be enabled for WireGuard
		HANDSHAKE_ENABLE="true"
	fi

	return 0;
}

# Function to ask for max peers
function ask_max_peers()
{
	# Ask for max peers
	local VALUE=$(whiptail --inputbox "Please enter the maximum number of peers you want to connect to:" 8 78 "$MAX_PEERS" --title "Max Peers" 3>&1 1>&2 2>&3)
	
	# Check if the user pressed Cancel
	if [ $? -ne 0 ]
	then
		return 1
	fi

	# Check if the user entered a value
	if [ -z "$VALUE" ]
	then
		return 2
	fi

	# Set value received from whiptail to MAX_PEERS
	MAX_PEERS=$VALUE
	return 0;
}

# Function to ask for moniker
function ask_moniker()
{
	# Ask for moniker
	local VALUE=$(whiptail --inputbox "Please enter your node's moniker:" 8 78 "$NODE_MONIKER" --title "Node Moniker" 3>&1 1>&2 2>&3)

	# Check if the user pressed Cancel
	if [ $? -ne 0 ]
	then
		return 1
	fi

	# Check if the user entered a value
	if [ -z "$VALUE" ]
	then
		return 2
	fi

	# Set value received from whiptail to NODE_MONIKER
	NODE_MONIKER=$VALUE
	return 0;
}

# Function to ask for node name
function ask_wallet_security()
{
	# Define the message
	MESSAGE="Do you wish to protect your wallet with a password? This will enhance security, but the password will be required every time the node restarts."
	
	# Display the whiptail dialog box
	if whiptail --title "Wallet Protection" --yes-button "Yes" --no-button "No" \
		--yesno "$MESSAGE" 10 78
	then
		BACKEND="file"
		output_info "Wallet protection is set to password-protected."
	else
		BACKEND="test"
		output_info "Wallet protection is disabled."
	fi
	
	return 0;
}

# Function to ask wallet passphrase
function ask_wallet_passphrase()
{
	# If BACKEND is not set to "file"
	if [ "$BACKEND" != "file" ]
	then
		return 0;
	fi
	
	# If WALLET_PASSPHRASE is not empty, return 0
	if [ ! -z "$WALLET_PASSPHRASE" ]
	then
		return 0;
	fi
	
	while true
	do
		# Ask for wallet passphrase
		WALLET_PASSPHRASE=$(whiptail --passwordbox "Please enter your wallet passphrase:" 8 78 \
			--title "Wallet Passphrase" 3>&1 1>&2 2>&3) || return 1;
		
		# Check if the user pressed Cancel
		if [ $? -ne 0 ]
		then
			return 1
		fi
		
		# Remove end of line and spaces at the beginning and end
		WALLET_PASSPHRASE=$(echo "$WALLET_PASSPHRASE" | tr -d '\r' | xargs)
		
		# Check that the user has entered a non-empty value of at least 8 characters.
		if [ ! -z "$WALLET_PASSPHRASE" ] && [ ${#WALLET_PASSPHRASE} -ge 8 ]
		then
			break
		fi
	done
	
	return 0;
}

####################################################################################################
# Messages functions
####################################################################################################

# Function to display a message to wait for funds
function message_wait_funds()
{
	# Get parameter balance checked
	local BALANCE_CHECKED=$1
	
	# Define message based on balance checked
	local MESSAGE="Please send at least 10 \$DVPN to the following address before continuing and starting the node:\n\n${PUBLIC_ADDRESS}\n\nPress 'Done' to check and continue or 'Quit' to exit."
	if [ "$BALANCE_CHECKED" = true ]
	then
		MESSAGE="The address seems to have ${WALLET_BALANCE}. Please send at least 10 DVPN to the following address before continuing and starting the node:\n\n${PUBLIC_ADDRESS}\n\nPress 'Done' to check again or 'Quit' to exit."
	fi
	
	# Display message to wait for funds and allow user to choose to quit or continue
	if whiptail --title "Funds Required" \
		--yes-button "Done" --no-button "Quit" \
		--yesno "$MESSAGE" 12 78
	then
		return 0
	else
		return 1
	fi
}

# Function to display a message to inform about Docker installation and reboot requirement
function message_docker_reboot_required()
{
	# Display message to inform about Docker installation and reboot requirement
	if whiptail --title "Docker Installation Complete" --yesno "Docker has been successfully installed on your system. For the installation to take full effect, a system reboot is required. Please select 'Reboot Now' to restart your system immediately, or choose 'Quit Without Reboot' if you prefer to reboot later at your own convenience." 12 78 --yes-button "Reboot Now" --no-button "Quit Without Reboot"
	then
		# Reboot the system
		output_info "Rebooting now... Please run the script again after the system has restarted."
		reboot
	else
		# Quit without rebooting
		output_success "Installation complete. Please reboot your system before continuing."
		exit 0
	fi
}

# Function to display gigabytes prices
function message_gigabyte_prices()
{
	local GIGABYTE_PRICES=$(grep "^gigabyte_prices\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	# Display message with gigabyte prices
	whiptail --title "Gigabyte Prices" --msgbox "Prices for one gigabyte of bandwidth provided:\n\n${GIGABYTE_PRICES}" 15 78
}

# Function to display hourly prices
function message_hourly_prices()
{
	local HOURLY_PRICES=$(grep "^hourly_prices\s*=" "${CONFIG_FILE}" | awk -F"=" '{gsub(/^[[:space:]]*|[[:space:]]*$/, "", $2); print $2}' | tr -d '"')
	# Display message with hourly prices
	whiptail --title "Hourly Prices" --msgbox "Prices for one hour of bandwidth provided:\n\n${HOURLY_PRICES}" 15 78
}

# Function to display port forwarding configuration message
function message_port_forwarding()
{
	local MESSAGE="Please ensure the following ports are forwarded in your router settings to allow external access to your node:\n\n"
	MESSAGE+="   - Node Port: ${NODE_PORT}/tcp\n"
	
	if [ "$NODE_TYPE" == "wireguard" ]
	then
		MESSAGE+="   - WireGuard Port: ${WIREGUARD_PORT}/udp\n"
	elif [ "$NODE_TYPE" == "v2ray" ]
	then
		MESSAGE+="   - V2Ray Port: ${V2RAY_PORT}/tcp\n"
	fi
	
	MESSAGE+="\nIt is essential that you complete this step to ensure that your node works properly and is accessible from the Internet.\n\n"
	MESSAGE+="For detailed instructions on configuring port forwarding, please consult our documentation at: https://docs.sentinel.co/\n\n\n"
	MESSAGE+="Press 'Continue' to test your port forwarding configuration."
	
	# Display the message using whiptail
	whiptail --title "Port Forwarding Required" --ok-button "Continue" --msgbox "$MESSAGE" 21 78
}

####################################################################################################
# Menu functions
####################################################################################################

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
	
	container_install || return 1;
	
	# Check if the sentinel node directory exists then create it
	if [ ! -d "${CONFIG_DIR}" ]
	then
		mkdir ${CONFIG_DIR} || { output_error "Failed to create Sentinel node directory."; return 1; }
	fi
	
	# If Certificate does not exist then generate it
	if [ ! -f "${CONFIG_TLS_CRT}" ] || [ ! -f "${CONFIG_TLS_KEY}" ]
	then
		certificate_generate || return 1;
	fi
	
	# Check if the configuration will be created
	local config_created=false;
	
	# If Sentinel config does not exist
	if [ ! -f "${CONFIG_FILE}" ]
	then
		# Change the value for force question
		config_created=true;
	fi
	
	# Generate Sentinel configurations
	generate_node_config || return 1;
	
	# Load configuration into variables
	load_config_files || return 1;
	
	# Check if the configuration will be changed
	local config_changed=false;
	
	# If Moniker is empty, ask for Moniker
	if [ -z "$NODE_MONIKER" ] || [ $config_created = true ]
	then
		ask_moniker || { output_error "Failed to get moniker."; return 1; }
		config_changed=true;
	fi
	
	# If Node Location is empty, ask for Node Location
	if [ -z "$NODE_LOCATION" ] || [ $config_created = true ]
	then
		ask_node_location || { output_error "Failed to get validation node type."; return 1; }
		config_changed=true;
	fi
	
	# If Node Type is empty, ask for Node Type
	if [ -z "$NODE_TYPE" ] || [ $config_created = true ]
	then
		ask_node_type || { output_error "Failed to get node type."; return 1; }
		config_changed=true;
		
		# Generate WireGuard or V2Ray configurations
		generate_vpn_config || { output_error "Failed to generate vpn configuration."; return 1; }
		# Load VPN configuration into variables
		load_vpn_config || { output_error "Failed to load vpn configuration."; return 1; }
	fi
	
	# If Remote IP is empty, ask for Remote IP
	if [ -z "$NODE_IP" ] || [ $config_created = true ]
	then
		ask_remote_ip || { output_error "Failed to get node IP."; return 1; }
		config_changed=true;
		ask_node_port
		ask_vpn_port
	fi
	
	# If Configuration has changed then refresh configuration files
	if [ $config_changed = true ] || [ $config_created = true ]
	then
		# Load network configuration from API (don't stop the script if it fails)
		load_network_configuration
		# Ask for defining the wallet security
		ask_wallet_security
		# Refresh configuration files
		refresh_config_files || return 1;
		# If configuration has changed, ask user to configure the firewall
		ask_firewall_configure "Do you want to automatically configure the firewall to allow incoming connections to the node?" || return 1;
	fi
	
	# Ask the user to enter his passphrase for the rest of the run
	ask_wallet_passphrase || { output_error "Failed to get wallet password."; return 1; }
	
	# Loop to initialize the wallet
	while true;
	do
		# Check if the wallet exists
		if ! wallet_exist
		then
			# Initialize the wallet
			wallet_initialization || return 1;
		fi
		# Get wallet addresses
		wallet_addresses || { output_error "Failed to get public address, please check your wallet configuration."; return 1; }
		
		# If addresses are not valid, display an error message
		if [[ ! ${PUBLIC_ADDRESS} == "sent"* ]] || [[ ! ${NODE_ADDRESS} == "sentnode"* ]];
		then
			output_error "Invalid addresses found, we will try to reinitialize the wallet."
			if whiptail --title "Wallet Initialization Issue" \
				--yes-button "OK" --no-button "Abort" \
				--yesno "There seems to be an issue with wallet initialization. We will remove the existing wallet and start the initialization process again. Please note that all data associated with the wallet will be permanently lost. You will need to enter the previously saved recovery words again.\n\nDo you want to proceed with wallet removal and re-initialization?" 10 78
			then
				wallet_remove || { output_error "Failed to remove wallet. Please do it manually by running the following command: docker run --rm --interactive --tty --volume ${CONFIG_DIR}:/root/.sentinelnode ${CONTAINER_NAME} process keys delete $WALLET_NAME"; return 1; }
			else
				output_info "Wallet removal aborted. Exiting the script."
				exit 1
			fi
		else
			break
		fi
	done
	
	# Variable to change waiting message
	local BALANCE_CHECKED=false;
	# Loop to wait for funds
	while true;
	do
		# Get wallet balance
		wallet_balance || { output_error "Failed to get wallet balance from the API."; return 1; }
		
		# If the wallet balance is empty or less than 1 DVPN, display a message to wait for funds
		if [ -z "$WALLET_BALANCE_AMOUNT" ] || [ "${WALLET_BALANCE_AMOUNT%.*}" -lt 10 ]
		then
			# Display message wallet balance is empty
			message_wait_funds $BALANCE_CHECKED || exit 1;
			BALANCE_CHECKED=true;
		else
			break
		fi
	done
	
	# Start the Sentinel node
	container_start || return 1;
	
	# If the container is not running, display an error message
	if ! container_running
	then
		output_error "Failed to start the dVPN node container."
		return 1
	fi
	
	# Show message to inform about port forwarding
	message_port_forwarding
	
	# Check if the node is accessible from the Internet
	network_check_port || return 1;
	
	# Get local IP address
	local LOCAL_IP=$(ip addr show wlan0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
	
	# Message to display after the node has been successfully installed and started
	local MESSAGE="Congratulations on successfully installing and starting your dVPN node! It is now fully operational and accessible from the Internet.\n\n"
	
	# If LOCAL_IP is not empty
	if [ ! -z "$LOCAL_IP" ]
	then
		MESSAGE+="Access the node dashboard at:\n"
		MESSAGE+="   - Local network: https://${LOCAL_IP}:${NODE_PORT}/status\n"
		MESSAGE+="   - From anywhere: https://${NODE_IP}:${NODE_PORT}/status\n"
	else
		MESSAGE+="Access the node dashboard at the following URL:\n"
		MESSAGE+="   https://${NODE_IP}:${NODE_PORT}/status\n"
	fi
	
	MESSAGE+="\nTo access and use your node as a dVPN server, please visit https://sentinel.co to find the dVPN applications that best suit your needs."
	
	# Display message indicating that the node has been successfully installed and started
	whiptail --title "Installation Complete" --msgbox "$MESSAGE" 16 100
	output_success "Congratulations on successfully installing and starting your dVPN node!"
	
	return 0;
}

# Function to display the configuration menu
function menu_configuration()
{
	# Load configuration into variables
	load_config_files || return 1;
	
	# Load wallet addresses
	ask_wallet_passphrase || { output_error "Failed to get wallet password."; return 1; }
	wallet_addresses || { output_error "Failed to get public address, wallet seems to be corrupted."; return 1; }

	CHOICE=$(whiptail --title "dVPN Node Manager" --menu "Welcome to the dVPN node configuration process.\n\nPlease select an option:" 16 78 6 \
		"Settings" "Modify node settings" \
		"Wallet" "Access wallet details" \
		"Certificate" "Access certificate details" \
		"Actions" "Manage node operations" \
		"Update" "Apply node updates" \
		"About" "View system and software details" \
		--ok-button "Select" --cancel-button "Finish" 3>&1 1>&2 2>&3)
	
	# Check if the user pressed the 'Finish' button, which is the cancel button now
	if [ $? -eq 1 ]
	then
		exit 0
	fi

	# Handle selected option
	case $CHOICE in
		"Settings")
			menu_settings
			;;
		"Wallet")
			menu_wallet
			;;
		"Certificate")
			menu_certificate
			;;
		"Actions")
			menu_actions
			;;
		"Update")
			menu_update
			;;
		"About")
			menu_about
			;;
	esac
}
# Function to display the settings menu
function menu_settings()
{
	while true;
	do
		local MESSAGE="Node Configuration:\n"
		MESSAGE+="  - Moniker: ${NODE_MONIKER}\n"
		MESSAGE+="  - Node Location: ${NODE_LOCATION}\n"
		MESSAGE+="  - Remote IP: ${NODE_IP}\n"
		MESSAGE+="  - Node Port: ${NODE_PORT}\n"
		if [ "$NODE_TYPE" = "wireguard" ]
		then
			MESSAGE+="  - WireGuard Port: ${WIREGUARD_PORT}\n"
		elif [ "$NODE_TYPE" = "v2ray" ]
		then
			MESSAGE+="  - V2Ray Port: ${V2RAY_PORT}\n"
		fi
		MESSAGE+="See more at: https://${NODE_IP}:${NODE_PORT}/status\n"
		MESSAGE+="\nChoose a settings group to configure:"
		
		CHOICE=$(whiptail --title "Settings" --menu "${MESSAGE}" 21 60 5 \
			"1" "Moniker" \
			"2" "Network" \
			"3" "VPN" \
			"4" "Gigabyte Prices" \
			"5" "Hourly Prices" \
			--cancel-button "Back" --ok-button "Select" 3>&1 1>&2 2>&3)
		
		# If user chooses 'Back', break the loop to return to previous menu
		EXITSTATUS=$?
		if [ $EXITSTATUS -eq 1 ]
		then
			break
		fi

		case $CHOICE in
			1)
				if ask_moniker && ask_node_location;
				then
					refresh_config_files || return 1;
					container_restart || return 1;
					# Display message indicating that the settings have been updated
					whiptail --title "Settings Updated" --msgbox "Node settings have been updated." 8 78
				fi
				;;
			2)
				if ask_remote_ip && ask_node_port && ask_vpn_port
				then
					ask_firewall_configure "Do you want to apply automatic port changes to the firewall?" || return 1;
					refresh_config_files || return 1;
					container_remove || return 1;
					container_start || return 1;
					# Display message indicating that the settings have been updated
					whiptail --title "Settings Updated" --msgbox "Network settings have been updated." 8 78
				fi
				;;
			3)
				if ask_node_type && ask_max_peers
				then
					remove_vpn_config_files || return 1;
					generate_vpn_config || return 1;
					refresh_config_files || return 1;
					container_restart || return 1;
					firewall_configure || return 1;
					# Display message indicating that the settings have been updated
					whiptail --title "Settings Updated" --msgbox "VPN settings have been updated." 8 78
				fi
				;;
			4)
				message_gigabyte_prices
				;;
			5)
				message_hourly_prices
				;;
		esac
	done
}

# Function to display the wallet menu
function menu_wallet()
{
	# Load configuration into variables
	wallet_addresses || { output_error "Failed to get public address, please check your wallet configuration."; return 1; }
	# Get wallet balance
	wallet_balance || { output_error "Failed to retrieve wallet balance, API may be down."; return 1; }
	
	# Set the width of the dialog box
	local WIDTH=78
	local LABEL_PUBLIC_ADDRESS="Public Address:"
	local LABEL_NODE_ADDRESS="Node Address:"
	local LABEL_BALANCE="DVPN Balance:"
	
	# Calculate space needed to right-align the addresses and balance
	local PAD_PUBLIC=$(printf '%*s' $((WIDTH - ${#PUBLIC_ADDRESS} - ${#LABEL_PUBLIC_ADDRESS} - 5)) "")
	local PAD_NODE=$(printf '%*s' $((WIDTH - ${#NODE_ADDRESS} - ${#LABEL_NODE_ADDRESS} - 5)) "")
	local PAD_BALANCE=$(printf '%*s' $((WIDTH - ${#WALLET_BALANCE} - ${#LABEL_BALANCE} - 5)) "")
	
	# Construct the display message
	local MESSAGE="${LABEL_PUBLIC_ADDRESS}${PAD_PUBLIC}${PUBLIC_ADDRESS}\n"
	MESSAGE+="${LABEL_NODE_ADDRESS}${PAD_NODE}${NODE_ADDRESS}\n"
	MESSAGE+="${LABEL_BALANCE}${PAD_BALANCE}${WALLET_BALANCE}"
	
	# Display wallet information and prompt for next action
	whiptail --title "Wallet Information" --msgbox "$MESSAGE" 12 $WIDTH
}

# Function to display the certificate information
function menu_certificate()
{
	
	while true;
	do
		# Display certificate information
		certificate_info || { output_error "Failed to get certificate information."; return 1; }
	
		# Construct the display message
		local MESSAGE="Certificate Information:\n"
		MESSAGE+="  - Creation date: ${CERTIFICATE_DATE_CREATION}\n"
		MESSAGE+="  - Expiration date: ${CERTIFICATE_DATE_EXPIRATION}\n"
		MESSAGE+="  - Issuer: ${CERTIFICATE_ISSUER}\n"
		MESSAGE+="  - Subject: ${CERTIFICATE_SUBJECT}"
		
		# Display certificate information
		if whiptail --title "Certificate Information" \
			--yes-button "Renew" --no-button "Back" --defaultno \
			--yesno "${MESSAGE}" 12 78
		then
			# Ask user to confirm certificate renewal
			if whiptail --title "Confirm Certificate Renewal" --yesno "Are you sure you want to renew the certificate?" 8 78
			then
				# Renew the certificate
				certificate_renew || { output_error "Failed to renew certificate."; return 1; }
				# Check if container is started
				if container_running
				then
					# Restart the container
					container_restart || { output_error "Failed to restart the container."; return 1; }
				fi
				
				# Display message indicating that the certificate has been renewed
				whiptail --title "Certificate Renewal" --msgbox "Certificate has been renewed successfully." 8 78
				output_success "Certificate has been renewed successfully."
			fi
		else
			break
		fi
	done
}

# Function to display the node menu
function menu_actions()
{
	local CHOICE=""
	local status_msg=""

	while true
	do
		# Check if the container is running
		if container_running
		then
			status_msg="dVPN node Status: Running"
			CHOICE=$(whiptail --title "Actions" \
				--yes-button "Select" --no-button "Back" \
				--menu "$status_msg\n\nChoose an option:" 15 78 4 \
				"Restart" "dVPN Node" \
				"Stop" "dVPN Node" \
				"Remove" "only the dVPN Node container" \
				"Wipe" "dVPN node container, wallet, and configuration folder" 3>&1 1>&2 2>&3)
		else
			status_msg="dVPN node Status: Stopped"
			CHOICE=$(whiptail --title "Actions" \
				--yes-button "Select" --no-button "Back" \
				--menu "$status_msg\nChoose an option:" 15 78 3 \
				"Start" "dVPN Node" \
				"Remove" "Only remove the dVPN Node container" \
				"Wipe" "Node container, wallet, and configuration folder" 3>&1 1>&2 2>&3)
		fi

		# Handle selected option
		case $CHOICE in
			"Restart")
				container_restart
				;;
			"Stop")
				container_stop
				;;
			"Start")
				container_start
				;;
			"Remove")
				if whiptail --title "Confirm Container Removal" --defaultno --yesno "Are you sure you want to remove the dVPN node container?" 8 78
				then
					# Remove the container
					container_remove

					# Ask user if they want to restart the installation or exit
					if whiptail --title "Restart Installation" --yesno "Do you want to restart the installation process?" 8 78
					then
						# Set variable to enable installation checks
						INSTALLATION_CHECKS_ENABLED=true
						# Exit to restart installation
						return 0
					else
						exit 0
					fi
					
					# Exit to restart installation
					return 0
				fi
				;;
			"Wipe")
				if whiptail --title "Confirm Container Removal" --defaultno --yesno "Are you sure you want to completely delete the dVPN node container, wallet, firewall rules and configuration folder?" 8 78
				then
					# Remove the container, wallet, and configuration folder
					load_config_files
					if ask_wallet_passphrase; then wallet_remove; fi
					container_remove
					firewall_reset
					remove_config_files

					# Ask user if they want to restart the installation or exit
					if whiptail --title "Restart Installation" --yesno "Do you want to restart the installation process?" 8 78
					then
						# Set variable to enable installation checks
						INSTALLATION_CHECKS_ENABLED=true
						# Exit to restart installation
						return 0
					else
						exit 0
					fi

					# Exit to restart installation
					return 0
				fi
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
	while true
	do
		# Menu pour choisir entre metre à jour le container et la configuration blockchain
		CHOICE=$(whiptail --title "Update Sentinel Node" --menu "Choose an option:" 15 60 5 \
			"Container" "Update the dVPN node container" \
			"Network" "Update the dVPN node network configuration" \
			--cancel-button "Back" --ok-button "Select" 3>&1 1>&2 2>&3)
		
		# If user chooses 'Back', break the loop to return to previous menu
		EXITSTATUS=$?
		if [ $EXITSTATUS -eq 1 ]
		then
			return 0
		fi
		
		case $CHOICE in
			"Container")
				update_container
				;;
			"Network")
				update_network
				;;
			
		esac
	done
	
	return 0;
}

# Function to display the about menu
function menu_about()
{
	# Get the current Node version
	local NODE_VERSION=$(docker run --rm --tty ${CONTAINER_NAME} process version | tr -d '\r')
	
	# Display the about menu using whiptail
	whiptail --title "About" --msgbox "
	Server Model: $(dmidecode -s system-product-name)
	Operating System: $(lsb_release -is) $(lsb_release -rs)
	Kernel Version: $(uname -r)
	Architecture: $(uname -m)
	Script Version: ${INSTALLER_VERSION}
	Node Version: ${NODE_VERSION}
	Sentinel Docs: ${DOCS_URL}" 15 60

	return 0;
}

####################################################################################################
# Main function
####################################################################################################

# Clear screen
clear

# Display the welcome message
echo -e "\e[94m"
echo "  ____             _   _            _ "
echo " / ___|  ___ _ __ | |_(_)_ __   ___| |"
echo " \___ \ / _ \ '_ \| __| | '_ \ / _ \ |"
echo "  ___) |  __/ | | | |_| | | | |  __/ |"
echo " |____/ \___|_| |_|\__|_|_| |_|\___|_|"
echo -e "\e[0m"
echo "--------------------------------------"
echo "          dVPN Node Manager"
echo "--------------------------------------"
echo ""
echo "Welcome to the Sentinel dVPN Node Manager!"
echo "This tool will assist you in installing, configuring, and managing your dVPN node."
echo "Here are your system's technical specifications:"
echo "Operating System: $(lsb_release -is) $(lsb_release -rs)"
echo "Kernel Version: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Script Version: ${INSTALLER_VERSION}"

# Check if the script is executed with sudo permissions
if [ "$(id -u)" != "0" ]
then
	echo -e "\e[31m[ERROR]\e[0m This script must be run with sudo permissions"
	exit 1
fi

# Check if whiptail is not installed
if ! command -v whiptail &> /dev/null
then
	output_info "Installing whiptail, please wait..."
	apt install -y whiptail || { echo -e "\e[31mFailed to install whiptail.\e[0m"; return 1; }
fi

# Check if jq is not installed
if ! command -v jq &> /dev/null
then
	output_info "Installing jq, please wait..."
	apt install -y jq || { output_error "Failed to install jq."; return 1; }
fi

# Check if curl is not installed
if ! command -v curl &> /dev/null
then
	output_info "Installing curl, please wait..."
	apt install -y curl || { output_error "Failed to install curl."; return 1; }
fi

# Check if openssl is not installed
if ! command -v openssl &> /dev/null
then
	output_info "Installing openssl, please wait..."
	apt install -y openssl || { output_error "Failed to install openssl."; return 1; }
fi

# If parameter "uninstall" is passed, remove the Sentinel node
if [ "$1" == "uninstall" ]
then
	# Ask for confirmation before uninstallation
	if ! whiptail --title "Confirm Uninstallation" --yes-button "Yes" --no-button "No" \
		--defaultno --yesno "Are you sure you want to uninstall the dVPN node?" 10 60
	then
		# User selected "No", so we do not uninstall
		echo "Uninstallation cancelled, no changes made."
		exit 0
	fi
	
	# Remove the wallet
	load_config_files || exit 1;
	ask_wallet_passphrase || exit 1;
	wallet_remove || exit 1;
	
	# Remove the Sentinel node
	container_remove || exit 1;
	
	# Remove firewall rules
	firewall_reset || exit 1;
	
	# Remove the configuration files
	remove_config_files || exit 1;
	
	# Remove the Sentinel node directory
	rm -rf ${CONFIG_DIR} || { output_error "Failed to remove dVPN node directory."; exit 1; }
	
	# Display message indicating that the dVPN node has been removed
	output_success "The dVPN node has been successfully removed."
	whiptail --title "Uninstallation Complete" --msgbox "The dVPN node has been successfully removed." 8 78
	
	# Exit the script
	exit 0
elif [ "$1" == "log" ] || [ "$1" == "logs" ]
then
	# Check if the container is running
	if ! container_running
	then
		output_error "The dVPN node container is not running."
		exit 1
	fi
	# Display the container logs
	container_logs || exit 1;
elif [ "$1" == "start" ]
then
	if container_running
	then
		output_error "The dVPN node container is already running."
		exit 1
	fi
	load_config_files || exit 1;
	ask_wallet_passphrase || exit 1;
	container_start || exit 1;
	output_info "The dVPN node container has been successfully started."
	whiptail --title "Start Complete" --msgbox "The dVPN node container has been successfully started." 8 78
elif [ "$1" == "stop" ]
then
	if ! container_running
	then
		output_error "The dVPN node container is already stopped."
		exit 1
	fi
	container_stop || exit 1;
	output_success "The dVPN node container has been successfully stopped."
	whiptail --title "Stop Complete" --msgbox "The dVPN node container has been successfully stopped." 8 78
elif [ "$1" == "restart" ]
then
	container_restart || exit 1;
	output_success "The dVPN node container has been successfully restarted."
	whiptail --title "Restart Complete" --msgbox "The dVPN node container has been successfully restarted." 8 78
elif [ "$1" == "status" ]
then
	if container_running
	then
		output_info "The dVPN node container is running."
		whiptail --title "Status" --msgbox "The dVPN node container is running." 8 78
	else
		output_info "The dVPN node container is stopped."
		whiptail --title "Status" --msgbox "The dVPN node container is stopped." 8 78
	fi
elif [ "$1" == "balance" ]
then
	load_config_files || exit 1;
	ask_wallet_passphrase || exit 1;
	wallet_addresses || { output_error "Failed to get public address, please check your wallet configuration."; return 1; }
	wallet_balance || exit 1;
	output_info "The node's wallet balance is: ${WALLET_BALANCE}"
	whiptail --title "Wallet Balance" --msgbox "The node's wallet balance is: ${WALLET_BALANCE}" 8 78
elif [ "$1" == "update" ]
then
	update_container || exit 1;
elif [ "$1" == "about" ]
then
	menu_about || exit 1;
elif [ "$1" == "check-port" ]
then
	load_config_files || exit 1;
	ask_wallet_passphrase || exit 1;
	wallet_addresses || { output_error "Failed to get public address, please check your wallet configuration."; return 1; }
	network_check_port || exit 1;
	whiptail --title "Port check" --msgbox "Congratulations! Your node is accessible from the Internet." 8 78
	output_success "Congratulations! The node is accessible from the Internet."
elif [ "$1" == "help" ]
then
	echo "This command is used to set up, configure and manage a dVPN node."
	echo "Usage: $(basename $0) [option]"
	echo ""
	echo "Options:"
	echo "  start       Start the dVPN node"
	echo "  stop        Stop the dVPN node"
	echo "  restart     Restart the dVPN node"
	echo "  status      Display the dVPN node status"
	echo "  balance     Display the dVPN node wallet balance"
	echo "  log         Display the dVPN node logs"
	echo "  check-port  Check if the node is accessible from the Internet"
	echo "  update      Update the dVPN node"
	echo "  uninstall   Remove the dVPN node"
	echo "  about       Display system and software details"
	echo "  help        Display this help message"
	exit 0
else
	while true
	do
		# Check if installation already exists
		if check_installation
		then
			# Disable installation checks
			INSTALLATION_CHECKS_ENABLED=false
			# Display the configuration menu
			menu_configuration;
		else
			# Display the installation menu
			menu_installation || exit 1;
		fi
	done
fi
