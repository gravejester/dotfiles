#!/bin/bash

# wpa_supplicant -B -i interface -c <(wpa_passphrase MYSSID passphrase)
# systemctl start dhcpcd
# curl https://raw.githubusercontent.com/gravejester/dotfiles/master/arch/install.sh -o ./install.sh
# curl https://raw.githubusercontent.com/gravejester/dotfiles/master/arch/install-vars.sh -o ./install-vars.sh
# chmod +x install.sh

source ./install-vars.sh

# Get wifi password
if [ "${WIFI_SETUP}" == "true" ]; then
    echo "Please enter password for wireless network '${WIFI_SSID}':"
    read -s WIFI_PASSWORD
fi

# Set keyboard layout
loadkeys ${KEYBOARD_LAYOUT}
echo "Keyboard layout: '${KEYBOARD_LAYOUT}'"

# Get boot mode
if [ -d "/sys/firmware/efi/efivars" ]; then
    BOOT_MODE="UEFI"
else
    BOOT_MODE="BIOS"
fi
echo "Boot Mode: '${BOOT_MODE}'"

# Set up network
#ln -s /usr/share/dhcpcd/hooks/10-wpa_supplicant /usr/lib/dhcpcd/dhcpcd-hooks/
echo "ctrl_interface=/run/wpa_supplicant" > /etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf
wpa_passphrase ${WIFI_SSID} ${WIFI_PASSWORD} >> /etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf
echo "Created wpa_supplicant configuration at '/etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf'"
echo "noarp" > /etc/dhcpd.conf
echo "Updated dhcpcd config"
systemctl restart dhcpcd
echo "Restarted dhcpcd service"

# Set NTP
timedatectl set-ntp true
echo "NTP activated"

# Partition disk
parted -s ${DISK} mktable msdos mkpart primary ext4 1MiB 100%
mkfs.ext4 "${DISK}1"
mount "${DISK}1" /mnt
echo "Partitioned '${DISK}'"

# Install base
pacstrap /mnt base base-devel vim

genfstab -U /mnt >> /mnt/etc/fstab
echo "Generated fstab"

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
echo "Localetime set"

hwclock --systohc
echo "Hardware clock set"

cp /etc/locale.gen /etc/locale.gen.bak
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "nb_NO.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen

cat <<EOT >> /etc/locale.conf
LANG=en_US.UTF-8
LC_ADDRESS=nb_NO.UTF-8
LC_IDENTIFICATION=nb_NO.UTF-8
LC_MEASUREMENT=nb_NO.UTF-8
LC_MONETARY=nb_NO.UTF-8
LC_NAME=nb_NO.UTF-8
LC_NUMERIC=nb_NO.UTF-8
LC_PAPER=nb_NO.UTF-8
LC_TELEPHONE=nb_NO.UTF-8
LC_TIME=nb_NO.UTF-8
EOT
echo "Updated /etc/locale.conf"

cat <<EOT >> /etc/vconsole.conf
KEYMAP=no-latin1
FONT=lat0-16
EOT
echo "Updated /etc/vconsole.conf"

echo "${HOSTNAME}" > /etc/hostname
echo "Hostname set"

cat <<EOT >> /etc/hosts
127.0.0.1   localhost.localdomain   localhost
::1         localhost.localdomain   localhost
127.0.0.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOT
echo "Updated /etc/hosts"

passwd

pacman -S grub

if [ "${INTEL_CPU}" == "true" ]; then
    pacman -S intel-ucode
fi

grub-install --target=i386-pc ${DISK}
grub-mkconfig -o /boot/grub/grub.cfg
echo "Installed GRUB"

useradd -m -G wheel -s /bin/bash ${USERNAME}
passwd ${USERNAME}
echo '%wheel ALL=(ALL) ALL' | sudo EDITOR='tee -a' visudo
echo "Created user '${USERNAME}'"

systemctl enable systemd-timesyncd
systemctl enable dhcpcd

exit
umount -R /mnt

echo "Finished initial installation of Arch Linux. Please reboot and log in as ${USERNAME}"