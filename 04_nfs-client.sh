#!/bin/bash

parallel-scp -h clientfile.txt $PWD/nfs-client.sh ~/nfs-client.sh
parallel-ssh -i -h clientfile.txt ~/nfs-client.sh
