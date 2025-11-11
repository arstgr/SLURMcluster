#!/bin/bash

export SCHEDROOT=/share/sched

sudo apt install -y libmunge-dev munge
sudo adduser -u 1111 munge --disabled-password --gecos "" -gid 1111
sudo adduser -u 1121 slurm --disabled-password --gecos "" -gid 1121

sudo useradd -r slurm -u 992
sudo mkdir /var/log/slurm
sudo chown slurm:slurm /var/log/slurm
sudo mkdir -p /var/spool/slurm
sudo chown slurm:slurm /var/spool/slurm

#sudo mkdir /var/log/slurmd.log
#sudo chown slurm:slurm /var/log/slurmd.log
sudo mkdir /var/spool/slurmd
sudo chown slurm:slurm /var/spool/slurmd

sudo ln -sf $SCHEDROOT/slurm/etc/slurm_path.sh /etc/profile.d/99_slurm_path.sh

sudo cp $SCHEDROOT/slurm/etc/munge.key /etc/munge/munge.key
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key
sudo systemctl enable munge
sudo systemctl restart munge

sudo apt install -y libevent-2.1-7 libevent-pthreads-2.1-7 hwloc

sudo cp $SCHEDROOT/slurm/etc/slurmd.service /usr/lib/systemd/system
sudo cp $SCHEDROOT/slurm/etc/slurmd.service /etc/systemd/system/

echo 'export PATH=/share/sched/slurm/22.05.3/bin:/share/sched/slurm/22.05.3/sbin:$PATH' | sudo tee /amlfs/sched/slurm/etc/slurm_path.sh
sudo ln -sf /share/sched/slurm/etc/slurm_path.sh /etc/profile.d/99_slurm_path.sh

sudo systemctl enable slurmd
sudo systemctl start slurmd

arch=$(dpkg --print-architecture)

curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.4.0/enroot_3.4.0-1_${arch}.deb
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.4.0/enroot+caps_3.4.0-1_${arch}.deb
sudo apt install -y ./enroot_3.4.0-1_${arch}.deb
sudo apt install -y ./enroot+caps_3.4.0-1_${arch}.deb
sudo apt install -y libnvidia-container1 libnvidia-container-tools --allow-change-held-packages

rm -f /tmp/enroot_3.4.0-1_${arch}.deb
rm -f /tmp/enroot+caps_3.4.0-1_${arch}.deb

sudo cp -fv /usr/share/enroot/hooks.d/50-slurm-pmi.sh /usr/share/enroot/hooks.d/50-slurm-pytorch.sh /etc/enroot/hooks.d
sudo sed -i '/set -eu/a export PATH=/share/sched/slurm/22.05.3/bin:$PATH' /etc/enroot/hooks.d/50-slurm-pytorch.sh
sudo sed -i '/shopt -s lastpipe/a export PATH=/share/sched/slurm/22.05.3/bin:$PATH' /etc/enroot/hooks.d/50-slurm-pmi.sh

sudo cp ~/apparmor.profile /etc/apparmor.d/usr.bin.enroot-nsenter
sudo apparmor_parser -r /etc/apparmor.d/usr.bin.enroot-nsenter
sudo aa-complain /usr/bin/enroot-nsenter
