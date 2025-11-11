#!/bin/bash

input_file="$1"
#node_list=$(paste -sd, "$input_file")
node_list=$(grep -v '^\s*#' "$input_file" | tr -d '\r' | paste -sd,)

echo "NodeName=${node_list} CPUs=144 Boards=1 SocketsPerBoard=2 CoresPerSocket=72 ThreadsPerCore=1 RealMemory=1635214 State=UNKNOWN Gres=gpu:4" >> slurm.conf
echo "PartitionName=debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP" >> slurm.conf
