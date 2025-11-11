#!/bin/bash

echo "Checking glibc version (Should be > 2.13)"
ldd --version | grep ldd

curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.5.0/enroot-check_3.5.0_$(uname -m).run
chmod +x enroot-check_*.run

./enroot-check_*.run --verify

echo "Checking if overlay is loaded into kernel (Should see overlay)"
lsmod | grep overlay

./enroot-check_*.run

echo "Testing kernel settings (All should be y or m)"
grep -E 'CONFIG_NAMESPACES|CONFIG_USER_NS|CONFIG_SECCOMP_FILTER|CONFIG_OVERLAY_FS' /boot/config-$(uname -r)


