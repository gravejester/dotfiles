#!/bin/bash

source ./install-vars.sh

sudo pacman -Syu
sudo pacman -S xorg xorg-xinit xorg-xinput mesa ${VIDEO_DRIVER} wireless_tools jq git

if ["${VM}" == "false" ]; then
    sudo pacman -S xorg-xbacklight
fi

cp /etc/X11/xinit/xinitrc ~/.xinitrc

cat <<EOT >> ~/.xserverrc
#!/bin/sh

exec /usr/bin/Xorg -nolisten tcp "$@" vt$XDG_VTNR
EOT

sudo cat <<EOT >> /etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
	Identifier "system-keyboard"
	MatchIsKeyboard "on"
	Option "XkbLayout" "no"
	Option "XkbModel" "pc105"
EndSection
EOT

sudo pacman -S xclock xterm twm

echo "Finished installing X - start with 'startx' command."