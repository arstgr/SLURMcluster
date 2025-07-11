#!/bin/bash
#

echo "Testing max_user_namespaces (Should be > 1)"
cat /proc/sys/user/max_user_namespaces

echo "Testing max_mnt_namespaces (Should be > 1)"
cat /proc/sys/user/max_mnt_namespaces

echo "Testing unprivileged_userns_clone (Should be > 1)"
cat /proc/sys/kernel/unprivileged_userns_clone

echo "Testing apparmor_restrict_unprivileged_userns (Should be 0)"
cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns


