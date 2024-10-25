#!/usr/bin/env bash
set -euo pipefail

MOUNT_POINT=/swap

if [ "$IS_ENABLE_SWAP" != "true" ]
then
  echo "Swap is not configured to enable, so exiting the script"
  exit 0
fi

############################ MOUNT SWAP VOLUME START #####################
sudo file -s "$SWAP_DEVICE_NAME"
sudo mkfs -t xfs "$SWAP_DEVICE_NAME"
sudo mkdir $MOUNT_POINT

echo "$SWAP_DEVICE_NAME  $MOUNT_POINT  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab
sudo mount -a

sudo chown ec2-user:ec2-user -R $MOUNT_POINT
############################ MOUNT SWAP VOLUME END #####################


############################ ENABLE SWAP SPACE START #####################
# create swap space with 8GB (= 64MiB * 128)
sudo dd if=/dev/zero of=$MOUNT_POINT/swapfile bs=64M count=128
sudo chmod 600 $MOUNT_POINT/swapfile
sudo mkswap $MOUNT_POINT/swapfile
sudo swapon $MOUNT_POINT/swapfile
sudo swapon -s
echo "$MOUNT_POINT/swapfile swap swap defaults 0 0"| sudo tee --append /etc/fstab
############################ ENABLE SWAP SPACE END ######################
