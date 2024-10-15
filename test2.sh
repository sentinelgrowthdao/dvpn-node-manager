#!/bin/bash


NODE_LOCATION="residential"

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
	local VALUE=$(whiptail --title "Node Location" --radiolist "Please select where your node is physically hosted:\n\n- A datacenter is a professional environment, typically offering stable power and internet connectivity.\n\n- A residential location is your home or office, where your node runs locally.\n\n" 18 78 2 \
		"datacenter" "Physically located in a professional datacenter" $datacenter_state \
		"residential" "Physically located at home or in a personal office" $residential_state 3>&1 1>&2 2>&3) || return 1;
	
	# Check if the user cancelled the dialog
	if [ -z "$VALUE" ]
	then
		return 1
	fi
	
	# Set value received from whiptail to NODE_LOCATION
	NODE_LOCATION=$VALUE
	return 0;
}


ask_node_location
