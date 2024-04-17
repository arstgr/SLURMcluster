#!/bin/bash

parallel-scp -h hostfile.txt $PWD/compute.sh ~/compute.sh
parallel-ssh -i -h hostfile.txt ~/compute.sh
