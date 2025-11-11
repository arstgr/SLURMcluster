#!/bin/bash
sudo mkdir /share

nvmes=($(lsblk -o NAME,TYPE,MOUNTPOINTS | awk '
{
    lines[NR]=$0
    types[NR]=$2
}
END {
    to_remove=""
    for (i=2; i<=NR; i++) {
        # If this line is a partition ("part"), mark it and the previous line to remove
        if (types[i] == "part") {
            to_remove = to_remove i " " (i-1) " "
        }
    }
    # Print lines that are "disk" and were NOT marked for removal
    split(to_remove, rm, " ")
    for (i=1; i<=NR; i++) {
        remove=0
        for (j in rm) { if (i == rm[j]) remove=1 }
        if (!remove && types[i] == "disk") {
            # Print just the disk name (first column), not the whole line
            split(lines[i], cols, " ")
            print cols[1]
        }
    }
}
'))

# Pair 3 nvmes for RAID
echo "RAID pair for nfs share: ${nvmes[0]} ${nvmes[1]} ${nvmes[2]}"

sudo mdadm --create /dev/md120 --level 0 --raid-devices 3 /dev/${nvmes[0]} /dev/${nvmes[1]} /dev/${nvmes[2]}
sudo mkfs.xfs /dev/md120
sudo mkdir /share
sudo mount /dev/md120 /share
sudo chmod 1777 /share

