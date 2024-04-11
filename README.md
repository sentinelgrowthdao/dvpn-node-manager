# dVPN Node Manager

This script `dvpn-node-manager.sh` is designed to facilitate the installation and use of Sentinel Config.

## Node Installation

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

4. Follow the installation process as indicated by the interface.

   If Docker is not already installed on the machine, it will be installed followed by a system reboot.

5. Restarting the script after installation will allow for modifying settings and managing the wallet or node.

## Uninstalling the Node

To uninstall the Sentinel Config node, you can execute the script with the `uninstall` parameter:

```bash
sudo bash dvpn-node-manager.sh uninstall
```

## Show logs

To show the logs of the Sentinel Config node, you can execute the script with the `logs` parameter:

```bash
sudo bash dvpn-node-manager.sh logs
```
