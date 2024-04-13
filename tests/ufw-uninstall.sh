#!/bin/bash

# Remove all ufw rules
ufw --force reset

# Disable ufw
ufw disable

# Uninstall ufw
apt-get -y purge ufw
