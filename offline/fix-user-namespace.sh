#!/bin/bash
#

#sudo apt install apparmor-utils -y
sudo aa-complain /etc/apparmor.d/*

sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
echo 'kernel.apparmor_restrict_unprivileged_userns=0' | sudo tee -a /etc/sysctl.d/99-enroot.conf
