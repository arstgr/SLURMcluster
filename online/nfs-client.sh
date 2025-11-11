#!/bin/bash

mount="/share"
#plae the IP address of the headnode here
server="10.0.0.4"

sudo apt install nfs-common -y
sudo mkdir $mount
sudo mount $server:$mount $mount
