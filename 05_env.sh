#!/bin/bash

parallel-scp -h hostfile.txt $PWD/env.sh ~/env.sh
parallel-ssh -i -h hostfile.txt ~/env.sh
