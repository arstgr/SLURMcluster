#!/bin/bash
sudo mkdir /mnt/resource_nvme
sudo mdadm --create /dev/md120 --level 0 --raid-devices 2 /dev/nvme1n1 /dev/nvme2n1  
sudo mkfs.xfs /dev/md120
sudo mount /dev/md120 /mnt/resource_nvme
sudo chmod 1777 /mnt/resource_nvme
