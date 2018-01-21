#!/bin/bash

# wpa_supplicant -B -i interface -c <(wpa_passphrase MYSSID passphrase)
# systemctl start dhcpcd
# curl https://raw.githubusercontent.com/gravejester/dotfiles/master/arch/install.sh -o ./install.sh
# curl https://raw.githubusercontent.com/gravejester/dotfiles/master/arch/install-vars.sh -o ./install-vars.sh
# chmod +x install.sh

source ./install-vars.sh

# Get wifi password
if [ "${WIFI_SETUP}" -eq "true" ]; then
    echo "Please enter password for wireless network '${WIFI_SSID}':"
    read -s WIFI_PASSWORD
fi

# Set keyboard layout
loadkeys ${KEYBOARD_LAYOUT}

# Get boot mode
if [ -d "/sys/firmware/efi/efivars" ]; then
    BOOT_MODE="UEFI"
else
    BOOT_MODE="BIOS"
fi

# Set up network
ln -s /usr/share/dhcpcd/hooks/10-wpa_supplicant /usr/lib/dhcpcd/dhcpcd-hooks/
echo "ctrl_interface=/run/wpa_supplicant" > /etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf
wpa_passphrase ${WIFI_SSID} ${WIFI_PASSWORD} >> /etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf
echo "noarp" > /etc/dhcpd.conf
systemctl start dhcpcd

timedatectl set-ntp true