# How to Install a Realtek r8169 Ethernet Driver on Ubuntu (Offline Method)

This guide details the process of installing a specific Realtek `r8169` Ethernet driver on an Ubuntu system that is offline, addressing common compilation, installation, and network configuration issues.

## Issue Description

The user's Ubuntu system, specifically an offline-computer running a recent kernel (e.g., 6.11.0-17-generic), had no internet connectivity via its Realtek Ethernet adapter. Initial diagnosis revealed that the network card was not recognized (`NO-CARRIER` or missing in `ip a`), or the system reported "no such device". This pointed to an issue with the kernel's default `r8169` driver not supporting the specific hardware revision of the Realtek chip. Furthermore, challenges included compiler version mismatches, missing development packages, and subsequent network configuration hurdles (missing DHCP client, incorrect IP routing, and physical cable faults).

**Target System:** Ubuntu (Desktop or Server), offline-computer
**Network Card:** Realtek Gigabit Ethernet (often uses `r8169` driver)
**Problem:** No Ethernet connectivity, network card not recognized or not functioning.

-----

## Prerequisites (on the ONLINE Computer)

Before starting on the offline Ubuntu machine, you'll need to prepare a USB drive with necessary files using an **online Ubuntu computer**.

1.  **Download the Realtek Driver:**

      * Go to the official Realtek website ([www.realtek.com](https://www.realtek.com)) and navigate to the "Downloads" section for Network Interface Controllers (NICs).
      * Find the latest Linux driver for your specific Realtek `PCIe GBE Family Controller`. Look for a driver package named similarly to `r8168-X.XX.XX.tar.bz2` or `r8169-X.XX.XX.tar.bz2`. (Note: Even if your chip is `r8168`, sometimes `r8169` drivers are provided or needed for newer kernels).
      * Download the `.tar.bz2` archive.

2.  **Create a script to download all necessary build packages:**

      * Create a directory on your online machine, e.g., `mkdir ~/offline_install_debs`.
      * Create a shell script named `get_debs.sh` inside this directory:
        ```bash
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
        ```
      * Make the script executable: `chmod +x get_debs.sh`
      * **CRITICAL:** Before running the script, determine the **exact kernel version** of your **offline machine** by running `uname -r` on it. Replace `"6.11.0-17-generic"` in the `OFFLINE_KERNEL_VERSION` variable in the script with that exact output.
      * **Run the script:** `./get_debs.sh`
      * This will download all required `.deb` packages into the `~/offline_install_debs` directory.

3.  **Copy Files to USB:**

      * Copy the downloaded Realtek driver `.tar.bz2` archive to your USB drive.
      * Copy the entire `~/offline_install_debs` folder (containing all the `.deb` files) to your USB drive.

-----

## On the OFFLINE Ubuntu Computer

Insert the prepared USB drive into your offline Ubuntu machine.

**Step 1: Install Build Dependencies and `dhclient`**

1.  **Mount the USB drive:**

      * Your USB drive will likely auto-mount to `/media/your_username/USB_DRIVE_LABEL`. You can verify its mount point with `df -h`.
      * Navigate to the directory containing the downloaded `.deb` packages:
        ```bash
        cd /media/offline-computer/USB/offline_install_debs # Adjust path if different
        ```

2.  **Clean apt cache and refresh package info:**

    ```bash
    sudo apt clean
    sudo apt update --allow-insecure-repositories --allow-unauthenticated -o Dir::Etc::SourceList="." -o Dir::Etc::SourceParts="." -o APT::Get::Trivial-Allow-Bad-URL=true
    sudo dpkg --clear-avail
    ```

    (These commands help ensure `apt` uses only the local `.deb` files you provide.)

3.  **Install all downloaded `.deb` packages:**

    ```bash
    sudo apt install ./*.deb
    ```

      * This command will install `build-essential`, `dkms`, kernel headers, and `isc-dhcp-client` along with their dependencies.
      * **Monitor the output for any errors**, especially "unmet dependencies". If you see errors, try `sudo apt --fix-broken install` and repeat.

**Step 2: Compile and Install the Realtek Driver**

1.  **Navigate to the Realtek driver archive on your USB:**

    ```bash
    cd /media/offline-computer/USB # Or wherever you copied the .tar.bz2
    ```

2.  **Extract the driver archive:**

    ```bash
    tar xfvj r8169-X.XX.XX.tar.bz2 # Replace with your driver's filename
    ```

    This will create a new directory, e.g., `r8169-X.XX.XX`.

3.  **Navigate into the extracted driver directory:**

    ```bash
    cd r8169-X.XX.XX # Adjust to your extracted directory name
    ```

4.  **Compile the driver:**

    ```bash
    make
    ```

      * You might see warnings about compiler differences or missing `vmlinux`. These are usually harmless for external module compilation and can be ignored.

5.  **Install the compiled driver:**

    ```bash
    sudo make install
    ```

      * **Permission Denied?** If you get "Permission denied," ensure you used `sudo`.
      * **"No rule to make target 'install'"?** This likely means you are in the `src` subdirectory. Return to the main driver directory (`cd ..` if you were in `src`) and try `sudo make install` again from there.
      * If `sudo make install` still fails with "No rule to make target 'install'" from the top-level directory, you can manually copy the module:
        ```bash
        sudo cp src/r8169.ko /lib/modules/$(uname -r)/kernel/drivers/net/ethernet/realtek/
        ```

6.  **Update kernel module dependencies and initramfs:**

    ```bash
    sudo depmod -a
    sudo update-initramfs -u
    ```

      * Ignore any "missing 'System.map'" warnings.

**Step 3: Network Configuration & Troubleshooting**

After installing the driver, your Ethernet card should be recognized. However, it might not have an IP address, or connectivity issues may persist.

1.  **Reboot your system:**

    ```bash
    sudo reboot
    ```

    This ensures the new driver is loaded and any old network state is cleared.

2.  **After reboot, check network interface status:**

    ```bash
    ip a
    ```

      * Look for an interface like `enp1s0`. It should show `state UP` and ideally an `inet` (IPv4) address if DHCP worked automatically. If it still shows `state DOWN`, try `sudo ip link set enp1s0 up`.

3.  **If no IPv4 address (and `dhclient` is installed):**

      * Try to obtain an IP address using `dhclient`:
        ```bash
        sudo dhclient enp1s0 # Replace enp1s0 with your interface name
        ```
      * Check `ip a` again. If still no IP, proceed to static IP configuration.

4.  **Static IP Configuration (if DHCP fails or `dhclient` not working):**

      * **Get your Router's IP and Subnet:** On an online device connected to your network, find your "Default Gateway" (router IP, e.g., `192.168.2.254`) and your "Subnet Mask" (e.g., `255.255.255.0` which is `/24`).

      * **Choose a Free IP:** Select an IP address within your router's subnet that is *not* already in use (e.g., `192.168.2.10`).

      * **Remove any old, conflicting IP addresses (IMPORTANT\!):**

        ```bash
        # If 'ip a' showed 192.168.1.10, remove it:
        sudo ip addr del 192.168.1.10/24 dev enp1s0
        ```

      * **Remove any old, incorrect default routes (IMPORTANT\!):**

        ```bash
        # If 'ip r' showed 'default via 192.168.1.1', remove it:
        sudo ip route del default via 192.168.1.1 dev enp1s0
        ```

      * **Assign the correct static IPv4 address for your machine:**

        ```bash
        sudo ip addr add 192.168.2.10/24 dev enp1s0 # Use your chosen IP and subnet
        ```

      * **Add the correct default gateway:**

        ```bash
        sudo ip route add default via 192.168.2.254 dev enp1s0 # Use your router's IP
        ```

          * If `ip addr add` or `ip route add` return "File exists" or "address already assigned," it means the configuration is already there. This is okay.

      * **Configure DNS servers (`/etc/resolv.conf`):**

          * Backup the existing file: `sudo cp /etc/resolv.conf /etc/resolv.conf.backup`
          * Edit the file: `sudo nano /etc/resolv.conf`
          * Delete any existing `nameserver` lines.
          * Add your DNS server IPs (e.g., your router's IP, or public DNS):
            ```
            nameserver 192.168.2.254 # Your router's IP (recommended first)
            # OR, if router DNS fails, use public DNS like Google's:
            # nameserver 8.8.8.8
            # nameserver 8.8.4.4
            ```
          * Save (Ctrl+S) and exit (Ctrl+X).

**Step 4: Final Connectivity Test (and Physical Debugging)**

1.  **Verify final network configuration:**

    ```bash
    ip a
    ip r
    cat /etc/resolv.conf
    ```

      * Ensure `ip a` shows only the correct `192.168.2.10/24` on `enp1s0`.
      * Ensure `ip r` shows `default via 192.168.2.254`.

2.  **Ping your router:**

    ```bash
    ping -c 4 192.168.2.254 # Use your router's IP
    ```

      * **SUCCESS:** If you get replies, your machine can communicate on your local network.
      * **FAILURE (`Destination Host Unreachable`):** This is the key. If your configuration is correct (verified by `ip a` and `ip r`), this indicates a **physical layer problem**.
          * **CRITICAL: Try a different Ethernet cable.** This was the ultimate solution in your case.
          * Try a different Ethernet port on your router.
          * Briefly reboot your router.

3.  **Ping a public website (using DNS):**

    ```bash
    ping -c 4 google.com
    ```

      * **SUCCESS:** You should now get replies, indicating full internet connectivity.
      * **FAILURE (`Temporary failure in name resolution`):** This means DNS isn't working. If `ping` to your router worked, then change `/etc/resolv.conf` to use public DNS servers (like `8.8.8.8` and `8.8.4.4`) instead of your router's IP. Save, then retry.

By following these steps, you should have a fully functional Ethernet connection on your Ubuntu offline-computer.
