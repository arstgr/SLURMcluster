# SLURM cluster
Scripts to Build a SLURM cluster on offline nodes

Thee scripts don't require a VMSS and can be built on a baremetal system or VM alike. It is only necesary to have all the nodes on the same network (vnet), so the nodes can communicate through TCP/IP via SSH. The setup relies on a shared files system (NSF/ANF or Lustre) which should be prepared beforehand (using the following instructions). The scripts should be run in the order of their names. 

To beging, clone this repo
```
git clone https://github.com/arstgr/SLURMcluster build
```
and change directory to 
```
cd build/offline
```

To proced, you need to prepare a hostfile from the nodes in the cluster. The host file could include the headnode also (in which case the headnode will act as one of the compute nodes as well) or could only include the compute nodes. The host file is formatted as a list of files, with each host listed on a separate line. Additionally a client file (copy of the hostfile, without the headnode), named as `clientfile.txt` is also necessary.  

Next, setup the shared file system and local NVMes. The shared file system could be mounted as an external lustre/ANF or built as an NFS drive out of the local disks on the headnode. The default setup currently uses 3 NVMe disks from one of the nodes and leaves the rest of the NVMes for local storage. The scripts assume the shared file system is mounted as "/share". 

If you are going to use an NFS drive, you should install the kernels necessary for nfs server on the host node. To do this, first download the package into your local machine,
```
wget http://launchpadlibrarian.net/754274580/nfs-kernel-server_2.6.4-3ubuntu5.1_arm64.deb
```
then move it to the host node (the node which hosts the NFS server), using scp or rsync or the likes of those. On the host node node run
```
sudo dpkg -i ./nfs-kernel-server_2.6.4-3ubuntu5.1_arm64.deb
```

Afterwards you can proceed by setting up the NFS server. To do this, run
```
./00_share.sh
```
to setup the shared file system. In case you plan to use an external FS (Lustre/ANF etc), skip this section.

Afterwards, setup the local NVMe disks. To proceed, run
```
./01_nvme.sh
```

Additionally, passwordless SSH needs to be enabled between all the nodes and from each node to itself. To enable this, paste your public and private SSH keys into the file `keys.sh`, and run
```
./02_keys.sh 
```
(you can skip this step if passwordless ssh is already enabled)

Afterwards, the shared file system needs to be mounted on all nodes. To start a NFS server with the `\share` from step 0, try
```
./03_nfs-server.sh
```
and setup NFS clients on the rest of the nodes. To do so, first add the IP address of the NFS server node (i.e. the host node) to the file `nfs-client.sh`. To obtain the IP address, try
```
ip a | grep -E "inet.*eth0" | awk '{print $2}' | cut -d '/' -f1
```
and once `nfs-client.sh` is edited, run 
```
./04_nfs-client.sh
```
Note that, `04_nfs-client.sh` needs to be modified, with the IP address of the NFS server added
Alternatively, you can mount an external FS on all nodes (mounted as `/share`), for example using `03_lustre_alternative.sh` (needs to be tuned/modified). 

Once the shared file system is set up on all nodes, prepare the necessary packages on your local machine and move them to the headnode of your cluster. To do so, run the scripts "offline-debs/download\_debs.sh" and "sources/download\_sources.sh". This will download the required packages into your local machine. Next, move these packages to directories on "/share". The packages downloaded with "offline-debs/download\_debs.sh" should be moved to "/share/offline-debs" while the packages downloaded with "sources/download\_sources.sh" should be moved to "/share/sources". Note that there is an extra script "offline-debs/install\_packages-offline.sh" that needs to be present in "/share/offline-debs", so when you move the packages to "/share/offline-debs" make sure to place this script there as well. 

Next you need to setup all nodes to be able to resolve the hostnames. To do so, copy the "/etc/hosts" file to "/share" directory, 
```
sudo cp /etc/hosts /share/hosts
```
then add all your node IP addresses and hostnames (in the form of "IP hostname" pairs) to this file. An example of this would look like
```
127.0.0.1 localhost   
IP_Node_1 Hostname_Node_1
IP_Node_2 Hostname_Node_2
etc
```
(keep the stuff at the end of the file as is and don't touch those, you should only add IP-Hostname pairs right after the first line, after "127.0.0.1 localhost" and don't change anything else)
Place this file in "/etc/" on all nodes in the cluster
```
parallel-ssh -i -h hostfile.txt "sudo cp /share/hosts /etc/hosts"
``` 

Next, slurm control daemon needs to be installed and configured. To do so, first fix the `slurm.conf` file. To do so, run
```
./tune-slurm-conf.sh hostnames.txt
./tune-gres-conf.sh hostnames.txt
```
The `hostnames.txt` is a file containing the hostnames of all compute nodes in the cluster (this could include the headnode if needed as well, so that the heanode can operate as a compute node, running jobs etc). To get the hostnames, you can try for example
```
parallel-ssh -h hostfile.txt -i "hostname" | grep <common pattern between hostnames> | tee -a hostnames.txt
```
Furthermore, set up the `SCHEDROOT` variable in `06_controller.sh`. This is where slurm and its plugins are installed. By default it is located on `/amlfs/sched` however if you are using a NFS file system, this need to be changed to `/share/sched` (lines 3, 36, 65, 69 and 71). Once all traces of `amlfs` are replaced with `share`, run
```
./06_controller.sh
```
This can take a while to compile, build and install. Afterwards, add slurm to your path
```
source $SCHEDROOT/slurm/etc/slurm_path.sh
```
This can/should also be added to your `.bashrc` file to load at login. For example (fix the paths)
```
echo 'PATH=/share/sched/slurm/23.11.05/bin:$PATH' >> ~/.bashrc
```

To make sure everything worked fine, try
```
sudo systemctl status slurmctld.service
```

Next, SLURM daemon needs to be set up on all the compute nodes. This current configuration relies on enroot for userspace priviledges. Due to settings in some OS images, enroot by default is unable to create and manage user name spaces. To fix this run 
```
./fix-user-namespace.sh```
This will fix some of the common issues with AppArmor.  

After checking/applying the necessary kernel settings for enroot, set up the proper paths in `compute.sh`. Similar to `06_controller.sh`, the environment variable `SCHEDROOT` need to be adjusted. Afterwards, run
```
./07_compute.sh clientfile.txt
```
If you need the headnode to be also included in the list of compute nodes (this is typical situation) and participate in the computations, instead try
```
./07_compute.sh hostfile.txt
```
(Notice clientfile.txt is essentially the hostfile.txt without the headnode)
This will take a while to complete. 

To check if things look fine, try
```
sudo systemctl status slurmd.service
```

## Bug in nvidia container library
Due to a bug in nvidia container library, you may face with an error like this
```
slurmstepd: error: pyxis: container start failed with error code: 1
slurmstepd: error: pyxis: printing contents of log file ...
slurmstepd: error: pyxis:     nvidia-container-cli: initialization error: open failed: /proc/self/ns/mnt: permission denied
slurmstepd: error: pyxis:     [ERROR] /etc/enroot/hooks.d/98-nvidia.sh exited with return code 1
slurmstepd: error: pyxis: couldn't start container
```

There are a couple of workarounds to resolve this issue. One of the easiest ones is to disable the container hooks. To do this, on all compute nodes run
```
sudo mv /etc/enroot/hooks.d/98-nvidia.sh /etc/enroot/hooks.d/98-nvidia.sh.disabled
```
This step is already implemented in the scripts. 

Afterwards, to submit slurm jobs try for example
```
srun --gres=gpu:4   -N 1 --ntasks=4  --container-image=nvcr.io/nvidia/pytorch:25.06-py3 --container-mounts=/dev:/dev python -c "import torch; print(torch.cuda.is_available())"
```

or 

```
srun --gres=gpu:4   -N 1 --ntasks=4   --export=ALL,ENROOT_ENABLE_GPU=1,PYXIS_OPTIONS="--no-nv --remap-uid=0 --remap-gid=0",ENROOT_NO_GPU_HOOK=1   --container-image=nvcr.io/nvidia/pytorch:25.06-py3 --container-mounts=/proc/self/ns:/proc/self/ns,/run/munge:/run/munge,/share/sched/slurm/etc:/etc/slurm,/dev:/dev python -c "import torch; print(torch.cuda.is_available())"
```
