#!/bin/bash

TIMELAPSE_BASE=`readlink -e ${BASH_SOURCE%/*}/..`
source $TIMELAPSE_BASE/config/camera-daemon.conf
TIMELAPSE_PIDFILE=$TIMELAPSE_BASE/config/camera-daemon.pid

# TODO implement:
# - TIMELAPSE_IS_CAPTURING
# - TIMELAPSE_CAPTURE_MODE
# - TIMELAPSE_TIMELAPSE_INTERVAL

case $1 in
    start)
        mkdir -p "$TIMELAPSE_CAPTURE_PATH/$TIMELAPSE_CAPTURE_FOLDER"

        /sbin/start-stop-daemon --start --background --make-pidfile --pidfile=$TIMELAPSE_PIDFILE --chdir=`pwd` \
            --exec /usr/bin/raspistill -- \
            "${TIMELAPSE_RASPISTILL_OPTIONS[@]}"
    ;;
    stop)
        /sbin/start-stop-daemon --stop --pidfile=$TIMELAPSE_PIDFILE --exec /usr/bin/raspistill
    ;;
esac
