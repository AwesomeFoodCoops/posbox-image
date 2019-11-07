#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Arguments
# Usage: sudo ./posbox_create_image.sh <branch> <addons>
REPOSITORY="https://github.com/AwesomeFoodCoops/odoo-production"
BRANCH=${1-9.0}

if [ $# -ge 2 ]; then
	ADDONS=$2
fi

file_exists() {
    [[ -f $1 ]];
}

require_command () {
    type "$1" &> /dev/null || { echo "Command $1 is missing. Install it e.g. with 'apt-get install $1'. Aborting." >&2; exit 1; }
}

require_command kpartx
require_command qemu-system-arm
require_command zerofree
require_command curl

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

MOUNT_POINT="${__dir}/root_mount"
OVERWRITE_FILES_BEFORE_INIT_DIR="${__dir}/overwrite_before_init"
OVERWRITE_FILES_AFTER_INIT_DIR="${__dir}/overwrite_after_init"

if [ -d "${MOUNT_POINT}" ]; then
	umount "${MOUNT_POINT}"
	rm -rf "${MOUNT_POINT}"
fi

if [ ! -f kernel-qemu ] || ! file_exists *raspbian*.img ; then
    ./posbox_download_images.sh
fi

cp -a *raspbian*.img posbox.img

PI_DIR="${OVERWRITE_FILES_BEFORE_INIT_DIR}/home/pi"
CLONE_DIR="$PI_DIR/odoo"
#rm -rf "${CLONE_DIR}"
if [ ! -d "${CLONE_DIR}" ]; then
	# Control will enter here if $DIRECTORY doesn't exist.
	mkdir -p  "${CLONE_DIR}"

	wget ${REPOSITORY}/archive/${BRANCH}.zip -O posbox.zip
	unzip posbox.zip
	mkdir -p "${CLONE_DIR}/addons/"

	cp -r odoo-production-$BRANCH/odoo/addons/web ${CLONE_DIR}/addons/
	cp -r odoo-production-$BRANCH/odoo/addons/web_kanban ${CLONE_DIR}/addons/
	cp -r odoo-production-$BRANCH/odoo/addons/hw_* ${CLONE_DIR}/addons/
        mkdir -p ${CLONE_DIR}/addons/point_of_sale/tools/posbox/
        cp -r odoo-production-$BRANCH/odoo/addons/point_of_sale/tools/posbox/configuration ${CLONE_DIR}/addons/point_of_sale/tools/posbox/
	cp -r odoo-production-$BRANCH/odoo/openerp ${CLONE_DIR}/
	cp -r odoo-production-$BRANCH/odoo/odoo.py ${CLONE_DIR}/

	cp -r odoo-production-$BRANCH/extra_addons/hw_* ${CLONE_DIR}/addons/
	cp -r odoo-production-$BRANCH/OCA_addons/hw_* ${CLONE_DIR}/addons/
	cp -r odoo-production-$BRANCH/louve_addons/hw_* ${CLONE_DIR}/addons/
	cp -r odoo-production-$BRANCH/intercoop_addons/hw_* ${CLONE_DIR}/addons/
	rm -rf posbox.zip
	rm -rf odoo-production-$BRANCH
fi

cd "${__dir}"

USR_BIN="${OVERWRITE_FILES_BEFORE_INIT_DIR}/usr/bin/"
if [ ! -d "${USR_BIN}" ]; then
	mkdir -p "${USR_BIN}"
	cd "/tmp"
	curl 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip' > ngrok.zip
	unzip ngrok.zip
	rm ngrok.zip
	cd "${__dir}"
	mv /tmp/ngrok "${USR_BIN}"
fi

# zero pad the image to be around 3.5 GiB, by default the image is only ~1.3 GiB
dd if=/dev/zero bs=1M count=2048 >> posbox.img

# resize partition table
START_OF_ROOT_PARTITION=$(fdisk -l posbox.img | tail -n 1 | awk '{print $2}')
(echo 'p';                          # print
 echo 'd';                          # delete
 echo '2';                          #   second partition
 echo 'n';                          # create new partition
 echo 'p';                          #   primary
 echo '2';                          #   number 2
 echo "${START_OF_ROOT_PARTITION}"; #   starting at previous offset
 echo '';                           #   ending at default (fdisk should propose max)
 echo 'p';                          # print
 echo 'w') | fdisk posbox.img       # write and quit

LOOP_MAPPER_PATH=$(kpartx -av posbox.img | tail -n 1 | cut -d ' ' -f 3)
LOOP_MAPPER_PATH="/dev/mapper/${LOOP_MAPPER_PATH}"
sleep 5

# resize filesystem
e2fsck -f "${LOOP_MAPPER_PATH}" # resize2fs requires clean fs
resize2fs "${LOOP_MAPPER_PATH}"

mkdir "${MOUNT_POINT}"
mount "${LOOP_MAPPER_PATH}" "${MOUNT_POINT}"

# 'overlay' the overwrite directory onto the mounted image filesystem
cp -a "${OVERWRITE_FILES_BEFORE_INIT_DIR}"/* "${MOUNT_POINT}"

# get rid of the git clone
#rm -rf "${CLONE_DIR}"
# and the ngrok usr/bin
#rm -rf "${OVERWRITE_FILES_BEFORE_INIT_DIR}/usr"

# get rid of the mount, we have to remount it anyway because we have
# to "refresh" the filesystem after qemu modified it
sleep 2
umount "${MOUNT_POINT}"

# from http://paulscott.co.za/blog/full-raspberry-pi-raspbian-emulation-with-qemu/
# ssh pi@localhost -p10022
# as of stretch with newer kernels, the versatile-pb.dtb file is necessary
QEMU_OPTS=(-kernel kernel-qemu -cpu arm1176 -m 256 -M versatilepb -dtb versatile-pb.dtb -nodefaults -no-reboot -serial stdio -append 'root=/dev/sda2 panic=1 rootfstype=ext4 rw' -hda posbox.img -net user,hostfwd=tcp::10022-:22,hostfwd=tcp::18069-:8069,hostfwd=tcp::10443-:443,hostfwd=tcp::10080-:80 -net nic)

if [ -z ${DISPLAY:-} ] ; then
    QEMU_OPTS+=(-nographic)
fi

echo "Booting qemu.."
qemu-system-arm "${QEMU_OPTS[@]}"

echo "Mounting drive.."
mount "${LOOP_MAPPER_PATH}" "${MOUNT_POINT}"

echo "Copying overwrite after init.."
cp -av "${OVERWRITE_FILES_AFTER_INIT_DIR}"/* "${MOUNT_POINT}"

# ADDONS CONFIG
# Replace --load=default,values for custom addons
if [ -z "$ADDONS" ]; then
	echo "Using default addons"
else
	echo "Patching rc.local with custom addons"
	sed -i -E "s/--load=(.*)/--load=$ADDONS" "${MOUNT_POINT}/etc/rc.local"
fi

# cleanup
echo "Cleanup"
sleep 2
umount "${MOUNT_POINT}"
rm -r "${MOUNT_POINT}"

echo "Running zerofree..."
zerofree -v "${LOOP_MAPPER_PATH}" || true

kpartx -d posbox.img
