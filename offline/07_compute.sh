#!/bin/bash

file=$1

parallel-scp -h ${file} $PWD/compute.sh ~/compute.sh
parallel-scp -h ${file} $PWD/apparmor.profile ~/apparmor.profile
parallel-ssh -i -h ${file} ~/compute.sh
