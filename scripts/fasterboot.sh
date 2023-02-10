#!/bin/bash
#
# Some bits of code to run as root (`sudo su`) to speed up boot times.
# Use at your own risk. See `references.md` file.

# Static IP:
# - Assign a static IP to your Raspberry Pi's mac adress on your router.
# - Add that static IP (uncomment and modify) to /etc/dhcpcd.conf
#

# Profiling systemd services using up startup time:
systemd-analyze blame

# Removing some services:
apt-get remove -y triggerhappy
systemctl disable rpi-eeprom-update.service
systemctl disable ModemManager.service
systemctl disable hciuart
systemctl disable keyboard-setup.service

# Linux boot speedup
cat <<EOF >> /boot/config.txt
disable_splash=1
boot_delay=0
dtoverlay=disable-bt
EOF
echo -n " loglevel=5 quiet " >> /boot/cmdline.txt


# DHCP speedup
cat <<EOF >> /etc/dhcpcd.conf
noarp
ipv4only
noipv6
EOF



