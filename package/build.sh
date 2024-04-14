#!/bin/bash

DIST_DIR=./dist/

# Supported architectures
ARCHITECTURES=("amd64" "armhf" "arm64")

# Check if the script is executed with sudo permissions
if [ "$(id -u)" != "0" ]; then
	echo -e "\e[31m[ERROR]\e[0m This script must be run with sudo permissions"
	exit 1
fi

# Check if debhelper dh-exec are installed
if ! dpkg -l debhelper > /dev/null 2>&1 || ! dpkg -l dh-exec > /dev/null 2>&1 || ! dpkg -l dh_make > /dev/null 2>&1;
then
	# Install debhelper dh-exec
	apt update && apt install -y debhelper dh-exec dh-make
fi

# Fix the permissions of the files
chmod +x debian/rules

# Iterate over each architecture
for ARCH in "${ARCHITECTURES[@]}"
do
	echo "Building for $ARCH..."
	dpkg-architecture -a$ARCH
	export DEB_BUILD_OPTIONS="nocheck"
	export DEB_HOST_ARCH=$ARCH
	dpkg-buildpackage -us -uc -b -a$ARCH
	
	find .. -maxdepth 1 -type f \( -name "*${ARCH}*.deb" -o -name "*${ARCH}*.buildinfo" -o -name "*${ARCH}*.changes" \) -exec mv {} ${DIST_DIR} \;
done

# Move generic .deb files
mv ../dvpn-node-manager_*.deb ${DIST_DIR} || echo "No generic .deb files to move."

# Reset architecture
dpkg-architecture -a$(dpkg --print-architecture)
