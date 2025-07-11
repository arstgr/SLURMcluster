#!/bin/bash

parallel-scp -h hostfile.txt $PWD/nvme.sh ~/nvme.sh
parallel-ssh -i -h hostfile.txt ~/nvme.sh
