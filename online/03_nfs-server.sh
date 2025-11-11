#!/bin/bash

sudo apt install nfs-kernel-server -y
sudo chown nobody:nogroup /share

echo "/share    *(rw,sync,no_subtree_check,no_root_squash,insecure)" | sudo tee /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

