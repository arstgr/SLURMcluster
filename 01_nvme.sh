#!/bin/bash
sudo mkdir /mnt/resource_nvme
sudo mdadm --create /dev/md120 --level 0 --raid-devices 8 /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1 /dev/nvme3n1 /dev/nvme4n1 /dev/nvme5n1 /dev/nvme6n1 /dev/nvme7n1
sudo mkfs.xfs /dev/md120
sudo mount /dev/md120 /mnt/resource_nvme
sudo chmod 1777 /mnt/resource_nvme
