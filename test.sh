#!/bin/bash

NODE_LOCATION="datacenter"
NODE_PORT="12345"
NODE_TYPE="wireguard"
WIREGUARD_PORT="54321"
V2RAY_PORT="54321"

# Function to display port forwarding configuration message
function message_port_forwarding()
{
	local MESSAGE=""

	if [ "$NODE_LOCATION" == "residential" ]; then
		MESSAGE="Please ensure the following ports are forwarded in your router settings to allow external access to your node:\n\n"
		MESSAGE+="   - Node Port: ${NODE_PORT}/tcp\n"
		
		if [ "$NODE_TYPE" == "wireguard" ]
		then
			MESSAGE+="   - WireGuard Port: ${WIREGUARD_PORT}/udp\n"
		elif [ "$NODE_TYPE" == "v2ray" ]
		then
			MESSAGE+="   - V2Ray Port: ${V2RAY_PORT}/tcp\n"
		fi
		
		MESSAGE+="\nIt is essential to complete this step for your node to function properly and be accessible from the Internet."
		MESSAGE+="\n\nFor detailed instructions on configuring port forwarding, please consult our documentation at: https://docs.sentinel.co/\n"
	else
		MESSAGE="Please wait a few seconds while we prepare to check the accessibility of the following ports for your node:\n\n"
		MESSAGE+="   - Node Port: ${NODE_PORT}/tcp\n"
		
		if [ "$NODE_TYPE" == "wireguard" ]
		then
			MESSAGE+="   - WireGuard Port: ${WIREGUARD_PORT}/udp\n"
		elif [ "$NODE_TYPE" == "v2ray" ]
		then
			MESSAGE+="   - V2Ray Port: ${V2RAY_PORT}/tcp\n"
		fi
		
		MESSAGE+="\nMake sure these ports are accessible to allow your node to function properly.\n"
	fi
	
	MESSAGE+="\n\nPress 'Continue' to test your port configuration."
	
	# Display the message using whiptail
	whiptail --title "Port Configuration Check" --ok-button "Continue" --msgbox "$MESSAGE" 21 78
}


message_port_forwarding
