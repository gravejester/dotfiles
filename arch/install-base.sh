#!/bin/bash

# wpa_supplicant -B -i interface -c <(wpa_passphrase MYSSID passphrase)
# systemctl start dhcpcd
# curl https://raw.githubusercontent.com/gravejester/dotfiles/master/arch/install-base.sh -o ./install-base.sh
# curl https://raw.githubusercontent.com/gravejester/dotfiles/master/arch/install-x.sh -o ./install-x.sh
# curl https://raw.githubusercontent.com/gravejester/dotfiles/master/arch/install-vars.sh -o ./install-vars.sh
# chmod +x install-base.sh
# chmod +x install-x.sh

source ./install-vars.sh

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


if [ "${WIFI_SETUP}" == "true" ]; then
    # Get wifi password
    echo "Please enter password for wireless network '${WIFI_SSID}':"
    read -s WIFI_PASSWORD
fi

# Set NTP
timedatectl set-ntp true
echo "NTP activated"

# Partition disk
if [ "${BOOT_MODE}" == "BIOS" ]; then    
    parted -s ${DISK} mktable msdos mkpart primary ext4 1MiB 100%
    parted -s ${DISK} set 1 boot on
    mkfs.ext4 "${DISK}1"
    mount "${DISK}1" /mnt
    echo "Partitioned '${DISK}'"
else
    parted -s ${DISK} mktable gpt mkpart ESP fat32 1MiB 513MiB mkpart primary ext4 513MiB 100%
    parted -s ${DISK} set 1 boot on
    mkfs.fat -F32 "${DISK}1"
    mkfs.ext4 "${DISK}2"
    mount "${DISK}1" /mnt/boot
    mount "${DISK}2" /mnt
    echo "Partitioned '${DISK}'"
fi

# Install base
pacstrap /mnt base base-devel vim

genfstab -U /mnt >> /mnt/etc/fstab
echo "Generated fstab"

cat <<EOT >> /mnt/etc/locale.conf
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

cat <<EOT >> /mnt/etc/vconsole.conf
KEYMAP=no-latin1
FONT=lat0-16
EOT
echo "Updated /etc/vconsole.conf"

cat <<EOT >> /mnt/etc/hosts
127.0.0.1   localhost.localdomain   localhost
::1         localhost.localdomain   localhost
127.0.0.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOT
echo "Updated /etc/hosts"

# Set up network
if [ "${WIFI_SETUP}" == "true" ]; then
    ln -s /usr/share/dhcpcd/hooks/10-wpa_supplicant /mnt/usr/lib/dhcpcd/dhcpcd-hooks/
    echo "ctrl_interface=/run/wpa_supplicant" > /mnt/etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf
    wpa_passphrase ${WIFI_SSID} ${WIFI_PASSWORD} >> /mnt/etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf
    echo "Created wpa_supplicant configuration at '/etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf'"
    echo "noarp" > /mnt/etc/dhcpd.conf
    echo "Updated dhcpcd config"
fi

cat <<EOT >> /mnt/root/install-base-p2.sh
#!/bin/bash

ln -s /usr/share/dhcpcd/hooks/10-wpa_supplicant /usr/lib/dhcpcd/dhcpcd-hooks/

#cp /etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf /mnt/etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf
#cp /etc/dhcpd.conf /mnt/etc/dhcpd.conf
#echo "Copied network setup to new filesystem"

ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
echo "Localetime set"

hwclock --systohc
echo "Hardware clock set"

cp /etc/locale.gen /etc/locale.gen.bak
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "nb_NO.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen

echo "${HOSTNAME}" > /etc/hostname
echo "Hostname set"

echo "Please set a password for 'root' user:"
passwd

pacman -S grub

if [ "${INTEL_CPU}" == "true" ]; then
    pacman -S intel-ucode
fi

grub-install --target=i386-pc ${DISK}
grub-mkconfig -o /boot/grub/grub.cfg
echo "Installed GRUB"

useradd -m -G wheel -s /bin/bash ${USERNAME}
echo "Please set a password for '${USERNAME}' user:"
passwd ${USERNAME}
echo '%wheel ALL=(ALL) ALL' | sudo EDITOR='tee -a' visudo
echo "Created user '${USERNAME}'"

systemctl enable systemd-timesyncd
systemctl enable dhcpcd

pacman -S acpi

if [ "${LAPTOP}" == "true" ]; then
    pacman -S xf86-input-libinput
fi

echo "Finished chroot install - please continue by entering 'exit'"
EOT

chmod +x /mnt/root/install-base-p2.sh

echo "Entering chroot - please continue the install by running '/root/install-base-p2.sh'"

arch-chroot /mnt

umount -R /mnt

echo "Finished initial installation of Arch Linux. Please reboot and log in as ${USERNAME}"