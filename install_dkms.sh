#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "[*] This script must be run as root"
   exit 1
fi

if [[ -f "/sys/bus/wmi/devices/7A4DDFE7-5B5D-40B4-8595-4408E0CC7F56/" ]]; then
    echo "[*] Sorry but your device doesn't have the required WMI module"
    exit 1
fi

# Remove previous chr devices if any exists
rm /dev/acer-gkbbl-0 /dev/acer-gkbbl-static-0 -f

MODULE_NAME=facer
VERSION=0.1
MOD_SRC_DIR="/usr/src/$MODULE_NAME-$VERSION"

rm -rf "$MOD_SRC_DIR"
mkdir -p "$MOD_SRC_DIR"

cp -R "$PWD/src/" "$MOD_SRC_DIR/src"
cp dkms.conf "$MOD_SRC_DIR/dkms.conf"
sed -i "s/PACKAGE_VERSION=.*/PACKAGE_VERSION=\"$VERSION\"/" "$MOD_SRC_DIR/dkms.conf"
dkms add -m "$MODULE_NAME" -v "$VERSION"
dkms build -m "$MODULE_NAME" -v "$VERSION"
dkms install -m "$MODULE_NAME" -v "$VERSION"
  
# module auto-loading
echo "blacklist acer_wmi" > /etc/modules-load.d/${MODULE_NAME}.conf
echo "wmi" >> /etc/modules-load.d/${MODULE_NAME}.conf
echo "sparse-keymap" >> /etc/modules-load.d/${MODULE_NAME}.conf
echo "video" >> /etc/modules-load.d/${MODULE_NAME}.conf
echo "${MODULE_NAME}" >> /etc/modules-load.d/${MODULE_NAME}.conf

exit 0

# compile the kernel module
make

# remove previous acer_wmi module
rmmod acer_wmi

# install required modules
modprobe wmi
modprobe sparse-keymap
modprobe video

# install facer module
insmod src/facer.ko
dmesg | tail -n 10
echo "[*] Done"