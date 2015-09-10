#!/bin/bash

TIMELAPSE_BASE=`readlink -e ${BASH_SOURCE%/*}/..`

REMOTE_LOGIN=${1}
REMOTE_PORT=${2}
LOCAL_PORT=${3}

(
    flock --exclusive --nonblock 200 || exit 0

    while true; do
        ssh -o ConnectTimeout=10 -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -N -R \*:$REMOTE_PORT:localhost:$LOCAL_PORT $REMOTE_LOGIN
        if [ $? -eq 130 ]; then
            break  # Ctrl + C
        fi
        sleep 5
    done
) 200>$TIMELAPSE_BASE/config/ssh-tunnel-$REMOTE_PORT.lock
