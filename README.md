# dVPN Node Manager

This script `dvpn-node-manager.sh` is designed to facilitate the installation, the configuration, and the management of the Sentinel dVPN node.

## Dependencies

The script is designed to run on a Linux-based operating system. The script has been tested on Ubuntu 22.04 LTS and Raspberry Pi OS (32-bit and 64-bit versions). The script is not guaranteed to work on other operating systems.

### Required Packages

The script automatically checks for and installs the necessary packages if they are not already present on your system. The required packages include: `whiptail`, `jq`, `curl`, `openssl`, `git`, and `docker`. These packages are required for script execution, JSON data processing, API requests, source control management and Docker container operation.

### API Endpoints

The script interacts with multiple external API endpoints to fetch external data:

- **GROWTHDAO API** to obtain the balance of the node address:
  - Endpoint: `https://api.sentinelgrowthdao.com/cosmos/bank/v1beta1/balances/`
- **FOXINODES API** for IP Checks:
  - Endpoint: `https://wapi.foxinodes.net/api/v1/sentinel/check-ip`
- **DYNDNS** for IP Checks (fallback if foxinodes API fails):
  - Endpoint: `https://checkip.dyndns.org`
- **FOXINODES API** to download the latest sentinel network configuration and avoid script updates:
  - Endpoint: `https://wapi.foxinodes.net/api/v1/sentinel/dvpn-node/configuration`
- **FOXINODES API** to control access to the API port from the Internet after node installation:
  - Endpoint: `https://wapi.foxinodes.net/api/v1/sentinel/dvpn-node/check-port`

### Required Docker Images

The script also depends on Docker images to run the dVPN node. These images are automatically downloaded according to the system configuration during script execution.

The following Docker images are available for download:

- **For general x86_64 architecture**:
  - `ghcr.io/sentinel-official/dvpn-node:latest`
- **For ARMv7 architecture (commonly used in devices like Raspberry Pi)**:
  - `wajatmaka/sentinel-arm7-debian:v0.7.1`
- **For ARM64 architecture**:
  - `wajatmaka/sentinel-aarch64-alpine:v0.7.1`

# Installation

## Installation via PPA (Personal Package Archive)

For Debian-based users, the simplest and most streamlined way of installing the `dvpn-node-manager` is through our Personal Package Archive (PPA). This method ensures that you receive the latest updates automatically and simplifies the installation process.

### Ubuntu

This step adds our repository to your system's list of sources, from which packages are retrieved. You can add the PPA by running the following command in your terminal:

```bash
sudo add-apt-repository ppa:foxinou/dvpn-node-manager
```

### Debian

Debian users need to add the PPA manually. Follow these steps to add the PPA and install the package:

1. Add the PPA key to your system:

```bash
curl -fsSL https://files.foxinodes.net/launchpad/foxinou_dvpn-node-manager.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/foxinou_dvpn-node-manager.gpg
```

2. Add the PPA to your sources list:

To add the PPA to your Debian 12 distribution, use the command below.

```bash
echo "deb http://ppa.launchpad.net/foxinou/dvpn-node-manager/ubuntu jammy main" | sudo tee /etc/apt/sources.list.d/foxinou_dvpn-node-manager.list
```

**Note:** If you are using Debian 11, you need to replace "jammy" with "focal".

### Install the `dvpn-node-manager`:

Now that your system is aware of the new repository, you can install the `dvpn-node-manager` package by executing:

```bash
sudo apt update
sudo apt install dvpn-node-manager
```

This command will download and install the `dvpn-node-manager` along with all required dependencies automatically.

### Running the dVPN Node Manager

Once the installation is complete, you can run the `dvpn-node-manager` using the following command:

```bash
sudo dvpn-node-manager
```

This will launch the dVPN Node Manager interface, allowing you to manage your dVPN node's settings and operations directly through a simple command-line interface.

### Uninstalling the Package

If you wish to uninstall the dVPN Node Manager, you can do so by executing:

```bash
sudo apt remove dvpn-node-manager
```

This command will remove the `dvpn-node-manager` package from your system. If you also want to remove the PPA from your list of software sources, use:

```bash
sudo add-apt-repository --remove ppa:foxinou/dvpn-node-manager
```

This will ensure that your system no longer checks for updates from the `dvpn-node-manager` PPA.

## Installation from Debian Package (manual)

For users on Debian-based systems, the `dvpn-node-manager` is available as a `.deb` package, which simplifies the installation process and automatically installs all required dependencies.

### Downloading the Package

You can manually download the .deb file of your choice by consulting [the available realses](https://github.com/sentinelgrowthdao/dvpn-node-manager/releases).

```bash
sudo wget -O /var/cache/apt/archives/dvpn-node-manager_latest.deb https://github.com/sentinelgrowthdao/dvpn-node-manager/releases/download/v1.0.0-alpha13/dvpn-node-manager_1.0.0-alpha13_$(dpkg --print-architecture).deb && sudo chmod 644 /var/cache/apt/archives/dvpn-node-manager_latest.deb && sudo chown _apt:root /var/cache/apt/archives/dvpn-node-manager_latest.deb
```

### Installing the Package

After manually downloading the .deb package, launch the installation using the `apt` package manager:

```bash
sudo apt install /var/cache/apt/archives/dvpn-node-manager_latest.deb
```

This command will install the dvpn-node-manager script and all necessary dependencies on your system. The package takes care of setting up everything needed for the script to run.

### Running the Script

Running the script using the `dvpn-node-manager` command:

```bash
sudo dvpn-node-manager
```

This command will launch the dVPN Node Manager, allowing you to manage your dVPN node's settings and operations directly through a simple command-line interface.

### Uninstalling the Package

If you wish to uninstall the dVPN Node Manager, you can do so by executing:

```bash
sudo apt autoremove /var/cache/apt/archives/dvpn-node-manager_latest.deb
```

This command will remove the dvpn-node-manager package from your system, as well as all configurations, docker images and containers.

## Installation from Source

To install the script from source, follow the steps below:

**Downloading the Script**

Download the script using the `curl` command:

```bash
curl -o $HOME/dvpn-node-manager.sh https://raw.githubusercontent.com/sentinelgrowthdao/dvpn-node-manager/main/dvpn-node-manager.sh
```

**Set execution permissions**

Grant execution permissions to the script using the `chmod` command:

```bash
chmod +x dvpn-node-manager.sh
```

**Running the Script**

Execute the script using the `sudo bash` command:

```bash
sudo bash dvpn-node-manager.sh
```

Follow the installation process as indicated by the interface. If Docker is not already installed on the machine, it will be installed followed by a system reboot.

Restarting the script after installation will allow for modifying settings and managing the wallet or node.

## Commands

A number of commands are available to perform actions outside the default interface.

```bash
sudo bash dvpn-node-manager.sh [command]
```

### Starting the Node

To start the dVPN node container, you can execute the script with the `start` parameter:

```bash
sudo bash dvpn-node-manager.sh start
```

### Stopping the Node

To stop the dVPN node container, you can execute the script with the `stop` parameter:

```bash
sudo bash dvpn-node-manager.sh stop
```

### Restarting the Node

To restart the dVPN node container, you can execute the script with the `restart` parameter:

```bash
sudo bash dvpn-node-manager.sh restart
```

### Status of the Node

To check the status of the dVPN node container, you can execute the script with the `status` parameter:

```bash
sudo bash dvpn-node-manager.sh status
```

### Show Wallet balance

To show the wallet balance, you can execute the script with the `balance` parameter:

```bash
sudo bash dvpn-node-manager.sh balance
```

### Show logs

To show the logs of the dVPN node container, you can execute the script with the `logs` parameter:

```bash
sudo bash dvpn-node-manager.sh logs
```

### Checking the Port

To check whether the port is open and accessible from the Internet, you can execute the script with the `port` parameter:

```bash
sudo bash dvpn-node-manager.sh port
```

### Updating the Node

To update the dVPN node container, you can execute the script with the `update` parameter:

```bash
sudo bash dvpn-node-manager.sh update
```

### Uninstalling the Node

To uninstall the dVPN node container, you can execute the script with the `uninstall` parameter:

```bash
sudo bash dvpn-node-manager.sh uninstall
```

### About the Script

To display information about the script, you can execute the script with the `about` parameter:

```bash
sudo bash dvpn-node-manager.sh about
```

### Help

To display the help message, you can execute the script with the `help` parameter:

```bash
sudo bash dvpn-node-manager.sh help
```
