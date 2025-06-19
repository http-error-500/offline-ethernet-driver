#!/bin/bash

# --- Configuration ---
DEB_DIR="$HOME/offline_install_debs"

# !!! CRITICAL: Set this to the EXACT KERNEL VERSION OF YOUR OFFLINE MACHINE !!!
# Get this by running 'uname -r' on your OFFLINE machine.
OFFLINE_KERNEL_VERSION="6.11.0-17-generic" # <<< REPLACE WITH YOUR OFFLINE KERNEL

# List of primary packages to install, including compiler tools, kernel headers, and dhclient.
# These are specific versions that worked for a 24.04-based system with GCC 13.
# Adjust versions if your online machine uses significantly different versions.
PRIMARY_PACKAGES="build-essential dkms \
                  linux-headers-${OFFLINE_KERNEL_VERSION} \
                  linux-hwe-6.11-headers-${OFFLINE_KERNEL_VERSION%-generic} \
                  binutils=2.42-4ubuntu2.5 binutils-common=2.42-4ubuntu2.5 libbinutils=2.42-4ubuntu2.5 binutils-x86-64-linux-gnu=2.42-4ubuntu2.5 \
                  gcc=4:13.2.0-7ubuntu1 gcc-13=13.3.0-6ubuntu2~24.04 gcc-x86-64-linux-gnu=4:13.2.0-7ubuntu1 \
                  g++=4:13.2.0-7ubuntu1 g++-13=13.3.0-6ubuntu2~24.04 g++-x86-64-linux-gnu=4:13.2.0-7ubuntu1 \
                  make dpkg-dev=1.22.6ubuntu6.1 libdpkg-perl=1.22.6ubuntu6.1 bzip2=1.0.8-5.1build0.1 lto-disabled-list=47 \
                  libc6-dev libstdc++-13-dev=13.3.0-6ubuntu2~24.04 libgcc-13-dev=13.3.0-6ubuntu2~24.04 \
                  libitm1=14.2.0-4ubuntu2~24.04 libasan8=14.2.0-4ubuntu2~24.04 liblsan0=14.2.0-4ubuntu2~24.04 libtsan2=14.2.0-4ubuntu2~24.04 libubsan1=14.2.0-4ubuntu2~24.04 libhwasan0=14.2.0-4ubuntu2~24.04 libquadmath0=14.2.0-4ubuntu2~24.04 \
                  fakeroot libalgorithm-merge-perl \
                  libctf-nobfd0 libctf0 libgprofng0 libsframe1 libfakeroot \
                  g++-13-x86-64-linux-gnu gcc-13-x86-64-linux-gnu \
                  libalgorithm-diff-perl \
                  libcc1-0 \
                  isc-dhcp-client"

# --- Rest of the script ---

mkdir -p "$DEB_DIR"
URLS_FILE="$DEB_DIR/download_urls.txt"
> "$URLS_FILE"

echo "--- Collecting download URIs for packages and all their recursive dependencies ---"
echo "Using kernel version: ${OFFLINE_KERNEL_VERSION}"
echo "This may take a moment as apt calculates all necessary packages."

sudo apt-get --download-only --yes --reinstall --no-install-recommends install $PRIMARY_PACKAGES --print-uris | grep '^http' | cut -d\' -f2 >> "$URLS_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to collect URIs. Check for issues with apt-get or package names."
    exit 1
fi

echo "--- Found $(wc -l < "$URLS_FILE") unique .deb URLs. ---"
echo "--- Downloading .deb files ---"
echo "All URIs saved to: $URLS_FILE"
echo "Downloading files to: $DEB_DIR"

wget -c -P "$DEB_DIR" --no-clobber -i "$URLS_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to download some files. Check network connection or file system."
    exit 1
fi

echo "--- Download process complete ---"
echo "Number of .deb files downloaded: $(find "$DEB_DIR" -maxdepth 1 -name "*.deb" | wc -l)"
echo "Please check the contents of '$DEB_DIR' and verify that all necessary .deb files are present."
echo "Then copy them to your USB drive along with your Realtek driver archive."