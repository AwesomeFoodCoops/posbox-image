#!/bin/sh

echo "Downloading raspbian.img.."
#wget 'https://downloads.raspberrypi.org/raspbian_lite_latest' -O raspbian.img.zip
wget 'http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2017-07-05/2017-07-05-raspbian-jessie-lite.zip' -O raspbian.img.zip
unzip raspbian.img.zip
rm raspbian.img.zip

wget 'https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/kernel-qemu-4.14.79-stretch' -O kernel-qemu
wget 'https://github.com/dhruvvyas90/qemu-rpi-kernel/raw/master/versatile-pb.dtb'

