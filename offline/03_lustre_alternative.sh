#!/bin/bash

sudo mkdir /amlfs
sudo mount -t lustre -o noatime,user_xattr 10.26.0.4@tcp0:/lustrefs /amlfs
