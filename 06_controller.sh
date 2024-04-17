#!/bin/bash

module load mpi/openmpi

export SCHEDROOT=/amlfs/sched
mkdir -p $SCHEDROOT/slurm/22.05.3
mkdir -p $SCHEDROOT/slurm/etc

sudo apt install -y libmunge-dev munge
sudo mungekey --create --force
sudo chown munge:munge /etc/munge/munge.key
sudo systemctl enable munge
sudo systemctl restart munge
sudo cp /etc/munge/munge.key $SCHEDROOT/slurm/etc

sudo mkdir -p $SCHEDROOT/pmix/v3
sudo apt install -y libevent-dev libhwloc-dev
wget https://github.com/openpmix/openpmix/archive/refs/tags/v3.1.6.tar.gz
tar xzf v3.1.6.tar.gz
cd openpmix-3.1.6
./autogen.sh
./configure --prefix=$SCHEDROOT/pmix/v3
sudo make -j install
cd ..
sudo rm -rf openpmix-3.1.6

sudo apt install -y libdbus-1-dev
wget https://download.schedmd.com/slurm/slurm-22.05.3.tar.bz2
tar xjf slurm-22.05.3.tar.bz2
cd slurm-22.05.3/
./configure --prefix=$SCHEDROOT/slurm/22.05.3 --sysconfdir=$SCHEDROOT/slurm/etc --with-pmix=$SCHEDROOT/pmix/v3 --with-hwloc --enable-pam --disable-x11
make -j 90
sudo make install
cd ..

echo 'export PATH=/amlfs/sched/slurm/22.05.3/bin:$PATH' | sudo tee $SCHEDROOT/slurm/etc/slurm_path.sh
sudo ln -s $SCHEDROOT/slurm/etc/slurm_path.sh /etc/profile.d/99_slurm_path.sh

sudo useradd -r slurm -u 992
sudo mkdir -p /var/log/slurm
sudo chown slurm:slurm /var/log/slurm
sudo mkdir -p /var/spool/slurm
sudo chown slurm:slurm /var/spool/slurm

sed -i -E "s/^SlurmctldHost.*/SlurmctldHost=$(hostname)/" slurm.conf
#sudo cp slurm.conf gres.conf cgroup.conf $SCHEDROOT/slurm/etc
sudo cp slurm.conf cgroup.conf $SCHEDROOT/slurm/etc

#sudo mkdir /var/spool/slurmctld
#sudo chown slurm:slurm /var/spool/slurmctld
#sudo mkdir /var/log/slurmctld.log
#sudo chown slurm:slurm /var/log/slurmctld.log

sudo cp slurm-22.05.3/etc/slurmctld.service /usr/lib/systemd/system
sudo cp slurm-22.05.3/etc/slurmctld.service /etc/systemd/system

sudo cp slurm-22.05.3/etc/slurmd.service $SCHEDROOT/slurm/etc

sudo systemctl enable slurmctld
sudo systemctl start slurmctld

wget https://github.com/NVIDIA/pyxis/archive/refs/tags/v0.11.1.tar.gz
tar xzf v0.11.1.tar.gz
cd pyxis-0.11.1
sudo CFLAGS='-I/amlfs/sched/slurm/22.05.3/include' prefix=$SCHEDROOT/slurm/22.05.3 make install
cd ..

sudo mkdir -p $SCHEDROOT/slurm/etc/plugstack.conf.d
echo 'include /amlfs/sched/slurm/etc/plugstack.conf.d/*' | sudo tee $SCHEDROOT/slurm/etc/plugstack.conf
sudo chown slurm:slurm $SCHEDROOT/slurm/etc/plugstack.conf
echo 'required /amlfs/sched/slurm/22.05.3/lib/slurm/spank_pyxis.so' | sudo tee $SCHEDROOT/slurm/etc/plugstack.conf.d/pyxis.conf
sudo chown slurm:slurm $SCHEDROOT/slurm/etc/plugstack.conf.d/pyxis.conf

sudo cp prolog.sh $SCHEDROOT/slurm/etc
sudo chown slurm:slurm $SCHEDROOT/slurm/etc/prolog.sh
sudo chmod 755 $SCHEDROOT/slurm/etc/prolog.sh
