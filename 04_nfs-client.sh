#!/bin/bash

parallel-scp -h clientfile.txt $PWD/build/nfs-client.sh $PWD/nfs-client.sh
parallel-ssh -i -h clientfile.txt $PWD/nfs-client.sh
