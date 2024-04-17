# SLURMcluster
Scripts to Build a SLURM cluster in Azure

Run the scripts in the order of their name

You need to paste your ssh public and private keys in the file "keys.sh"

The IP address of the NFS server (your headnode) needs to be set in the file "nfs-client.sh"

Paste the IP addresses of all the nodes inside the file "hostfile.txt"

The scripts also install pyxis and enroot, thereby allowing docker containers to run on the cluster
