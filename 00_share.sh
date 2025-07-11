#!/bin/bash
sudo mkdir /share
sudo mkfs.xfs /dev/nvme3n1
sudo mount /dev/nvme3n1 /share
sudo chmod 1777 /share

