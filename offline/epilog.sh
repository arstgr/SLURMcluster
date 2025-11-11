#!/bin/bash
# Restore Munge socket ownership after job

SOCKET="/run/munge/munge.socket.2"
ORIG_FILE="/tmp/munge.orig.$SLURM_JOB_ID"

if [ -e "$SOCKET" ] && [ -f "$ORIG_FILE" ]; then
    ORIG_OWNER=$(cat "$ORIG_FILE")
    chown $ORIG_OWNER "$SOCKET"
    rm -f "$ORIG_FILE"

    echo "[$(date)] Restored $SOCKET ownership to $ORIG_OWNER after job $SLURM_JOB_ID" >> /var/log/slurm-epilog.log
fi

