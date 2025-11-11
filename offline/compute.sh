#!/bin/bash

export SCHEDROOT=/share/sched
sudo bash /share/offline-debs/install_packages-offline.sh

sudo systemctl stop munge || true
sudo groupmod -g 1111 munge
sudo usermod -u 1111 -g 1111 munge
sudo chown -R munge:munge /var/log/munge
sudo chown -R munge:munge /etc/munge
sudo chown -R munge:munge /var/lib/munge
sudo systemctl start munge
sudo systemctl status munge
sudo chown -R munge:munge /var/run/munge

sudo addgroup --system --gid 986 slurm
sudo adduser  --system --uid 992  --gid 986  --disabled-login --disabled-password --no-create-home --gecos "" --shell /usr/sbin/nologin slurm

sudo mkdir /var/log/slurm
sudo chown slurm:slurm /var/log/slurm
sudo mkdir -p /var/spool/slurm
sudo chown slurm:slurm /var/spool/slurm

sudo touch /var/log/slurmd.log
sudo chown slurm:slurm /var/log/slurmd.log
sudo mkdir /var/spool/slurmd
sudo chown slurm:slurm /var/spool/slurmd

#sudo unlink /etc/profile.d/99_slurm_path.sh
sudo ln -sf $SCHEDROOT/slurm/etc/slurm_path.sh /etc/profile.d/99_slurm_path.sh

sudo cp $SCHEDROOT/slurm/etc/munge.key /etc/munge/munge.key
sudo chown munge:munge /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key
sudo systemctl enable munge
sudo systemctl restart munge

sudo cp $SCHEDROOT/slurm/etc/slurmd.service /usr/lib/systemd/system
sudo cp $SCHEDROOT/slurm/etc/slurmd.service /etc/systemd/system/

echo 'export PATH=/share/sched/slurm/23.11.5/bin:/share/sched/slurm/23.11.5/sbin:$PATH' | sudo tee /share/sched/slurm/etc/slurm_path.sh
#unlink /etc/profile.d/99_slurm_path.sh
sudo ln -sf /share/sched/slurm/etc/slurm_path.sh /etc/profile.d/99_slurm_path.sh

sudo systemctl enable slurmd
sudo systemctl start slurmd

sudo cp -fv /usr/share/enroot/hooks.d/50-slurm-pmi.sh /usr/share/enroot/hooks.d/50-slurm-pytorch.sh /etc/enroot/hooks.d
sudo sed -i '/set -eu/a export PATH=/share/sched/slurm/23.11.5/bin:$PATH' /etc/enroot/hooks.d/50-slurm-pytorch.sh
sudo sed -i '/shopt -s lastpipe/a export PATH=/share/sched/slurm/23.11.5/bin:$PATH' /etc/enroot/hooks.d/50-slurm-pmi.sh

sudo cp /share/apparmor.profile /etc/apparmor.d/usr.bin.enroot-nsenter
sudo apparmor_parser -r /etc/apparmor.d/usr.bin.enroot-nsenter
sudo rm /etc/apparmor.d/enroot
sudo aa-complain /usr/bin/enroot-nsenter

sudo mv /etc/enroot/hooks.d/98-nvidia.sh /etc/enroot/hooks.d/98-nvidia.sh.disabled
