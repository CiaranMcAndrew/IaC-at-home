#!/bin/bash

ZIPFILE="${1}"
URL="https://github.com/pftf/RPi3/releases/download/v1.39/RPi3_UEFI_Firmware_v1.39.zip"

echo 'Make a UEFI boot disk for raspberry Pi'
if [ -z $ZIPFILE ] ; then 
echo "using the file ${ZIPFILE}"
else
echo "by downloading from ${URL}"
fi
echo 
echo '*** WARNING**** this will delete everything on the target disk'
echo 'use the command lsblk to verify you have the right device name'
echo

while getopts ":d:" opt; do
  case $opt in
    d) DISK="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac

  case $OPTARG in
    -*) echo "Option $opt needs a valid argument"
    exit 1
    ;;
  esac
done

# will default to the environment variable DISK if it is set and nothing entered above
DISK=${DISK:-$NEWDISK}

echo "Using disk: $DISK"

if [ ! -b $DISK ] ; then
echo "cant find the disk: $DISK" 
exit 1
fi

PARTITION=${DISK}1

sudo umount $PARTITION

set -e

sudo sfdisk $DISK <<EOT
label: dos
label-id: 0x71d59d14
device: $DISK
unit: sectors

$PARTITION : start=        2048, size=    2000000000, type=c, bootable
EOT

mkdir -p sdcard
sudo mkfs.fat $PARTITION
sudo mount $PARTITION sdcard

if [ -z $ZIPFILE ] ; then 
# no zipfile specified - download the firmware from github
curl -L ${URL} -o uefi.firmware.zip
cd sdcard
sudo unzip ../uefi.firmware.zip
rm ../uefi.firmware.zip
else
# use the zipfile specified in ${1}
cd sdcard
sudo unzip ../$ZIPFILE
fi

cd ..
sudo umount $PARTITION

rmdir sdcard
