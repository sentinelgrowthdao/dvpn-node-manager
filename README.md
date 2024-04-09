# sentinel-installer.sh

This script `sentinel-installer.sh` is designed to facilitate the installation and use of Sentinel Config.

## Installation

To install Sentinel Config, you can follow the steps below.

1. Download the script using the `curl` command:

```bash
curl -o $HOME/sentinel-installer.sh https://raw.githubusercontent.com/Foxinodes/sentinel-installer/main/sentinel-installer.sh
```

2. Grant execution permissions to the script using the `chmod` command:

```bash
chmod +x sentinel-installer.sh
```

3. Execute the script using the `sudo bash` command:

```bash
sudo bash sentinel-installer.sh
```

4. Follow the installation process as indicated by the interface.

   If Docker is not already installed on the machine, it will be installed followed by a system reboot.

5. Restarting the script after installation will allow for modifying settings and managing the wallet or node.
