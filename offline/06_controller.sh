#!/bin/bash

module load mpi/hpcx

export SCHEDROOT=/share/sched
mkdir -p $SCHEDROOT/slurm/23.11.5
mkdir -p $SCHEDROOT/slurm/etc

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

sudo mungekey --create --force
sudo chown munge:munge /etc/munge/munge.key
sudo systemctl enable munge
sudo systemctl restart munge
sudo cp /etc/munge/munge.key $SCHEDROOT/slurm/etc

sudo mkdir -p $SCHEDROOT/pmix/v4
cp /share/sources/pmix-4.2.9.tar.gz .
tar xzf pmix-4.2.9.tar.gz 
cd pmix-4.2.9
./configure --prefix=$SCHEDROOT/pmix/v4
sudo make -j install
cd ..
sudo rm -rf pmix-4.2.9

cp /share/sources/slurm-23.11.5.tar.bz2 .
tar xjf slurm-23.11.5.tar.bz2
cd slurm-23.11.5/
./configure --prefix=$SCHEDROOT/slurm/23.11.5 --sysconfdir=$SCHEDROOT/slurm/etc --with-pmix=$SCHEDROOT/pmix/v4 --with-hwloc --enable-pam --disable-x11
make -j 90
sudo make install
cd ..

echo 'export PATH=/share/sched/slurm/23.11.5/bin:$PATH' | sudo tee $SCHEDROOT/slurm/etc/slurm_path.sh
#sudo unlink /etc/profile.d/99_slurm_path.sh
sudo ln -s $SCHEDROOT/slurm/etc/slurm_path.sh /etc/profile.d/99_slurm_path.sh

sudo addgroup --system --gid 986 slurm
sudo adduser  --system --uid 992  --gid 986  --disabled-login --disabled-password --no-create-home --gecos "" --shell /usr/sbin/nologin slurm

sudo mkdir -p /var/log/slurm
sudo chown slurm:slurm /var/log/slurm
sudo mkdir -p /var/spool/slurm
sudo chown slurm:slurm /var/spool/slurm

sed -i -E "s/^SlurmctldHost.*/SlurmctldHost=$(hostname)/" slurm.conf
#sudo cp slurm.conf gres.conf cgroup.conf $SCHEDROOT/slurm/etc
sudo cp slurm.conf cgroup.conf gres.conf $SCHEDROOT/slurm/etc

sudo mkdir /var/spool/slurmctld
sudo chown slurm:slurm /var/spool/slurmctld
sudo touch /var/log/slurmctld.log
sudo chown slurm:slurm /var/log/slurmctld.log

sudo cp slurm-23.11.5/etc/slurmctld.service /usr/lib/systemd/system
sudo cp slurm-23.11.5/etc/slurmctld.service /etc/systemd/system

sudo cp slurm-23.11.5/etc/slurmd.service $SCHEDROOT/slurm/etc

sudo systemctl enable slurmctld
sudo systemctl start slurmctld
sudo systemctl status slurmctld

cp /share/sources/v0.20.0.tar.gz .
tar xzf v0.20.0.tar.gz
cd pyxis-0.20.0
sudo CFLAGS='-I/share/sched/slurm/23.11.5/include' prefix=$SCHEDROOT/slurm/23.11.5 make install
cd ..

sudo mkdir -p $SCHEDROOT/slurm/etc/plugstack.conf.d
echo 'include /share/sched/slurm/etc/plugstack.conf.d/*' | sudo tee $SCHEDROOT/slurm/etc/plugstack.conf
sudo chown slurm:slurm $SCHEDROOT/slurm/etc/plugstack.conf
echo 'required /share/sched/slurm/23.11.5/lib/slurm/spank_pyxis.so' | sudo tee $SCHEDROOT/slurm/etc/plugstack.conf.d/pyxis.conf
sudo chown slurm:slurm $SCHEDROOT/slurm/etc/plugstack.conf.d/pyxis.conf

sudo cp prolog.sh $SCHEDROOT/slurm/etc
sudo chown slurm:slurm $SCHEDROOT/slurm/etc/prolog.sh
sudo chmod 755 $SCHEDROOT/slurm/etc/prolog.sh

sudo cp $PWD/apparmor.profile /share/apparmor.profile
