#!/bin/bash

mount="/share"
#plae the IP address of the headnode here
server="IP of HeadNode"

sudo apt install nfs-common -y
sudo mkdir $mount
sudo mount $server:$mount $mount
