#!/bin/bash

parallel-scp -h hostfile.txt $PWD/keys.sh ~/keys.sh
parallel-ssh -i -h hostfile.txt ~/keys.sh
