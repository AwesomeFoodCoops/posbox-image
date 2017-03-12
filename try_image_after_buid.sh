#!/bin/sh


IMAGE_FILE=posboxv2.img
MOUNT_POINT="mount_point"
START_OF_ROOT_PARTITION=$(fdisk -l ${IMAGE_FILE} | tail -n 1 | awk '{print $2}')

mkdir ${MOUNT_POINT}
sudo mount -v -o offset=$((512*${START_OF_ROOT_PARTITION})) -t ext4 ${IMAGE_FILE} ${MOUNT_POINT}

# changer fstab
sudo sed -i 's/^\([^proc]\)/#\1/g' ${MOUNT_POINT}/etc/fstab

# changer /etc/ld.so.preload
sudo sed -i 's/^\(.\)/#\1/g' ${MOUNT_POINT}/etc/ld.so.preload

# supprimer hw_escpos des modules odoo à charger dans /etc/rc.local
sudo sed -i 's/,hw_escpos//g' ${MOUNT_POINT}/etc/rc.local

# changer /home/pi/odoo/addons/point_of_sale/tools/posbox/configuration/led_status.sh
sudo sed -i 's/^\(.\)/#\1/g' ${MOUNT_POINT}/home/pi/odoo/addons/point_of_sale/tools/posbox/configuration/led_status.sh

sudo umount ${MOUNT_POINT}
sleep 5
rm -Rf ${MOUNT_POINT}

# EXEC the VM
qemu-system-arm -kernel kernel-qemu -cpu arm1176 -m 256 -M versatilepb -no-reboot -serial stdio -append 'root=/dev/sda2 panic=1 rootfstype=ext4 rw' -hda ${IMAGE_FILE} -net user,hostfwd=tcp::10022-:22,hostfwd=tcp::18069-:8069,hostfwd=tcp::10443-:443,hostfwd=tcp::10080-:80 -net nic

mkdir ${MOUNT_POINT}
sudo mount -v -o offset=$((512*${START_OF_ROOT_PARTITION})) -t ext4 ${IMAGE_FILE} ${MOUNT_POINT}

#CLEAN THE IMAGE FILE
sed -i '' 's/^#//g' ${MOUNT_POINT}/etc/fstab
sed -i '' 's/^#//g' ${MOUNT_POINT}/etc/ld.so.preload
sed -i '' 's/,hw_scanner/,hw_scanner,hw_escpos/g' ${MOUNT_POINT}/etc/rc.local
sed -i '' 's/^#//g' ${MOUNT_POINT}/home/pi/odoo/addons/point_of_sale/tools/posbox/configuration/led_status.sh

sudo umount ${MOUNT_POINT}
sleep 5
rm -Rf ${MOUNT_POINT}
