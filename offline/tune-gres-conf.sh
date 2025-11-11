#!/bin/bash

input_file="$1"

for i in $(cat ${input_file}); do
	echo "Nodename=$i Name=gpu Count=4 File=/dev/nvidia[0-3]" >> gres.conf
done
