# dVPN Node Manager

This script `dvpn-node-manager.sh` is designed to facilitate the installation, the configuration, and the management of the Sentinel dVPN node.

## Installation

To install Sentinel Config, you can follow the steps below.

1. Download the script using the `curl` command:

```bash
curl -o $HOME/dvpn-node-manager.sh https://raw.githubusercontent.com/Foxinodes/dvpn-node-manager/main/dvpn-node-manager.sh
```

2. Grant execution permissions to the script using the `chmod` command:

```bash
chmod +x dvpn-node-manager.sh
```

3. Execute the script using the `sudo bash` command:

```bash
sudo bash dvpn-node-manager.sh
```

4. Follow the installation process as indicated by the interface. If Docker is not already installed on the machine, it will be installed followed by a system reboot.

5. Restarting the script after installation will allow for modifying settings and managing the wallet or node.

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
