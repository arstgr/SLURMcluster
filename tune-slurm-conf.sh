#!/bin/bash

input_file="$1"
#node_list=$(paste -sd, "$input_file")
node_list=$(grep -v '^\s*#' "$input_file" | tr -d '\r' | paste -sd,)

echo "NodeName=${node_list} CPUs=128 Boards=1 SocketsPerBoard=2 CoresPerSocket=64 ThreadsPerCore=1 RealMemory=1635214 State=UNKNOWN" >> slurm.conf
echo "PartitionName=debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP" >> slurm.conf
