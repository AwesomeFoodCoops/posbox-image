#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

# Recommends: antiword, graphviz, ghostscript, postgresql, python-gevent, poppler-utils
export DEBIAN_FRONTEND=noninteractive

mount /dev/sda1 /boot

echo "================>> Enable root user"
echo "================>> TODO after reboot : manually change root and pi paswords !"
echo "root:rasp" | chpasswd


echo "================>> Update the package list"
apt update
echo "================>> Upgrade the system"
apt -y dist-upgrade

echo "================>> Install the needed system packages"
PKGS_TO_INSTALL="htop w3m adduser postgresql-client python python-unidecode python-dateutil python-decorator python-docutils python-feedparser python-imaging python-jinja2 python-ldap python-libxslt1 python-lxml python-mako python-mock python-openid python-passlib python-psutil python-psycopg2 python-pychart python-pydot python-pyparsing python-pypdf python-reportlab python-requests python-tz python-vatnumber python-vobject python-werkzeug python-xlwt python-yaml postgresql python-gevent python-serial python-pip python-dev localepurge vim mc mg screen iw hostapd isc-dhcp-server git rsync console-data"

apt -y install ${PKGS_TO_INSTALL}

apt clean
localepurge
rm -rf /usr/share/doc


echo "================>> Install the needed python packages"
# python-usb in wheezy is too old
# the latest pyusb from pip does not work either, usb.core.find() never returns
# this may be fixed with libusb>2:1.0.11-1, but that's the most recent one in raspbian
# so we install the latest pyusb that works with this libusb
pip install pyusb==1.0.0b1
pip install pycountry==1.20
pip install qrcode
pip install evdev
pip install simplejson
pip install unittest2
pip install babel

echo "================>> Enable ssh & postgresql systemctl service"
systemctl enable ssh
systemctl enable postgresql

echo "================>> Add system user pi to usbusers system group"
groupadd usbusers
usermod -a -G usbusers pi
usermod -a -G lp pi

echo "================>> Create log directory"
mkdir /var/log/odoo
chown pi:pi /var/log/odoo

echo "================>> Settle logrotate"
# logrotate is very picky when it comes to file permissions
chown -R root:root /etc/logrotate.d/
chmod -R 644 /etc/logrotate.d/
chown root:root /etc/logrotate.conf
chmod 644 /etc/logrotate.conf

echo "================>> Add cron task to empty the /var/run/odoo/sessions directory"
echo "* * * * * rm /var/run/odoo/sessions/*" | crontab -

echo "================>> Remove AP and DHCP automatic conf"
update-rc.d -f hostapd remove
update-rc.d -f isc-dhcp-server remove

echo "================>> Reload systemctl service configurations"
systemctl daemon-reload

#create dirs for ramdisks
create_ramdisk_dir () {
    mkdir "${1}_ram"
}

#echo "================>> Create ramdisk directories"
#create_ramdisk_dir "/var"
#create_ramdisk_dir "/etc"
#create_ramdisk_dir "/tmp"
#mkdir /root_bypass_ramdisks

#echo "================>> Enable ramdisk systemctl service"
#systemctl enable ramdisks.service
#systemctl disable dphys-swapfile.service

echo "================>> Enable setupcon"
# https://www.raspberrypi.org/forums/viewtopic.php?p=79249
# to not have "setting up console font and keymap" during boot take ages
setupcon

echo "================>> Install Apache2"
apt -y install apache2

echo "================>> Generate selfsigned certificate"
mkdir /etc/apache2/ssl
cd /etc/apache2/ssl
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/C=FR/ST=Denial/L=Paris/O=Dis/CN=posbox"  -keyout posbox.key  -out posbox.cert

echo "================>> Enable Apache Modules"
a2enmod ssl
a2enmod rewrite
a2enmod proxy_http
a2enmod headers

echo "================>> Enable Odoo vhost"
a2ensite odoo
a2dissite 000-default.conf

echo "================>> Reload Apache2 Configuration"
systemctl reload apache2

chown -R pi:pi /home/pi
touch /boot/ssh

echo "================>> Start postgresql service"
systemctl start postgresql

echo "================>> Create postgres profile for pi system user"
sudo -u postgres createuser -s pi

echo "================>> end"
#halt