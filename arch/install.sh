#!/bin/bash

# wget

source ./install-vars.sh

if [ "${WIFI_SETUP}" -eq "true" ]; then
    echo "Please enter password for wireless network '${WIFI_SSID}':"
    read -s WIFI_PASSWORD
fi

loadkeys ${KEYBOARD_LAYOUT}

if [ -d "/sys/firmware/efi/efivars" ]; then
    BOOT_MODE="UEFI"
else
    BOOT_MODE="BIOS"
fi

systemctl start dhcpcd

ln -s /usr/share/dhcpcd/hooks/10-wpa_supplicant /usr/lib/dhcpcd/dhcpcd-hooks/

cat <<EOT >> /etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf
network={
    ssid="${WIFI_SSID}"
    psk="${WIFI_PASSWORD}"
}
EOT