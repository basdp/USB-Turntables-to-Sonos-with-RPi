#!/bin/bash
#
# Description:
# Automated install script for https://github.com/basdp/USB-Turntables-to-Sonos-with-RPi
#
# The easiest way to run this, if you don't have git already installed is
# cd /tmp && wget https://github.com/basdp/USB-Turntables-to-Sonos-with-RPi/archive/master.zip && unzip master.zip && USB-Turntables-to-Sonos-with-RPi-master/scripts/install.sh
#
# If you have troubles with your device number in asound.conf, there is commented-out code below that may help you.

THIS_DIR="$(readlink -m "$(dirname "$0")")"

if [[ $EUID != 0 ]]; then
    echo "Gaining root privileges to install software."
    exec sudo "$0" "$*"
fi
echo " ... Running as root now."

echo -e "\n\nInstalling darkice and icecast2.\nSay 'yes' to icecast config and accept the defaults or change passwords as you want.\n"
sleep 3
apt-get update
apt-get install -y darkice icecast2

update-rc.d darkice remove
update-rc.d icecast2 remove

for i in $(find "$THIS_DIR/../files" -type f)
do
    dest="$(echo "$i" | sed -e 's/.*files//')"
    echo "cp $i $dest"
    cp "$i" "$dest"
done


## As long as "card CODEC" works for you, you do not need this.
# card_input_usb="$(arecord -l | grep -m 1 "^card" | awk '{print $2}' | sed -e 's/:$//' )"
# if ! [[ "$card_input_usb" =~ ^[0-9]+$ ]] ; then
#    card_input_usb=1
# fi
# echo "Setting HW input card numeber to $card_input_usb"
# sed -i -e "s/ card 1/ card $card_input_usb/" /etc/asound.conf


systemctl enable icecast2
systemctl enable darkice

exit 0
