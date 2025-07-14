# SLURM cluster
Scripts to Build a SLURM cluster in Azure

Thee scripts don't require a VMSS and can be built on a baremetal system or VM alike. It is only necesary to have all the nodes on the same network (vnet), so the nodes can communicate through TCP/IP via SSH. The setup relies on a shared files system (NSF/ANF or Lustre) which should be prepared beforehand. The scripts should be run in the order of their names. 

To beging, clone this repo
```
git clone https://github.com/arstgr/SLURMcluster build
```
and change directory to 
```
cd build
```

To proced, you need to prepare a hostfile from the nodes in the cluster. The host file could include the headnode also (in which case the headnode will act as one of the compute nodes as well) or could only include the compute nodes. The host file is formatted as a list of files, with each host listed on a separate line. Additionally a client file (copy of the hostfile, without the headnode), named as `clientfile.txt` is also necessary. 

Next, setup the shared file system and local NVMes. The shared file system could be mounted as an external lustre/ANF or built as an NFS drive out of the local disks on the headnode. The default setup currently uses 1 NVMe disk from one of the nodes and leaves the rest of the NVMes for local storage. The scripts assume the shared file system is mounted as "/share". To use the default setup, run
```
./00_share.sh
```
to setup the shared file system. In case you plan to use an external FS (Lustre/ANF etc), skip this section.

Afterwards, setup the local NVMe disks. This includes creating a raid array, formatting, mounting and setting up the proper permissions. To proceed, run
```
./01_nvme.sh
```

Additionally, passwordless SSH needs to be enabled between all the nodes and from each node to itself. To enable this, paste your public and private SSH keys into the file `keys.sh`, and run
```
./02_keys.sh 
```

Afterwards, the shared file system needs to be mounted on all nodes. To start a NFS server with the `\share` from step 0, try
```
./03_nfs-server.sh
```
and setup NFS clients on the rest of the nodes. To do so, first add the IP address of the NFS server to the file `nfs-client.sh`. To obtain the IP address, try
```
ip a | grep -E "inet.*eth0" | awk '{print $2}' | cut -d '/' -f1
```
and once `nfs-client.sh` is edited, run 
```
./04_nfs-client.sh
```
Note that, `04_nfs-client.sh` needs to be modified, with the IP address of the NFS server added
Alternatively, you can mount an external FS on all nodes (mounted as `/share`), for example using `03_lustre_alternative.sh` (needs to be tuned/modified). 

Once the shared file system is set up on all nodes, prepare the environment by running
```
./05_env.sh
```
This will install the necassary packages for ubuntu. This stepp can take a few minutes to finish.

Next, slurm control daemon needs to be installed and configured. To do so, first fix the `slurm.conf` file. To do so, run
```
./tune-slurm-conf.sh hostnames.txt
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
echo 'PATH=/share/sched/slurm/22.05.3/bin:$PATH' >> ~/.bashrc
```

To make sure everything worked fine, try
```
sudo systemctl status slurmctld.service
```

Next, SLURM daemon needs to be set up on all the compute nodes. This current configuration relies on enroot for userspace priviledges. To make sure the environment/kernel settings are proper for the containers to be run without priviledges, first run `./test-enroot.sh` to check if the kernel settings are proper. Additionally run `./test-kernel.sh` to see if some of the kernel settings are proper. If everything checks (which usually doesn't), run `./fix-user-namespace.sh`. This will fix some of the common issues with AppArmor. Afterwards, run `./test-enroot.sh` to make sure everything checks fine. 

After checking/applying the necessary kernel settings for enroot, set up the proper paths in `compute.sh`. Similar to `06_controller.sh`, the environment variable `SCHEDROOT` need to be adjusted, along with instance were `amlfs` is to be replaced with `share`, similar to that in `06_controller.sh`. These include lines 3, 33 (2 instances), 34, 48, 49 and 50. Afterwards, run
```
./07_compute.sh clientfile.txt
```
If you need the headnode to be included in the list of compute nodes and participate in the computations, instead try
```
./07_compute.sh hostfile.txt
```
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
Afterwards, to submit slurm jobs try for example
```
srun --gres=gpu:4   -N 1 --ntasks=4  --container-image=nvcr.io/nvidia/pytorch:25.06-py3 --container-mounts=/dev:/dev python -c "import torch; print(torch.cuda.is_available())"
```

or 

```
srun --gres=gpu:4   -N 1 --ntasks=4   --export=ALL,ENROOT_ENABLE_GPU=1,PYXIS_OPTIONS="--no-nv --remap-uid=0 --remap-gid=0",ENROOT_NO_GPU_HOOK=1   --container-image=nvcr.io/nvidia/pytorch:25.06-py3 --container-mounts=/proc/self/ns:/proc/self/ns,/run/munge:/run/munge,/share/sched/slurm/etc:/etc/slurm,/dev:/dev python -c "import torch; print(torch.cuda.is_available())"
```
