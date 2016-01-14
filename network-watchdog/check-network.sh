#!/bin/bash

LOG=/home/pi/capture/check-network.log
USB_ID_WLAN0="1-1.3"

log_size=`stat --format="%s" $LOG`

if [ $log_size -gt $((100*1024)) ]
then
    mv $LOG $LOG.old
fi

exec >> $LOG
exec 2>> $LOG

log() {
    echo "$(date --rfc-3339=seconds): $*"
}


DEFAULT_GATEWAY=$(ip route show default | awk '/^default/ {print $3}')

PING_OK=0
if [ "$DEFAULT_GATEWAY" != "" ]; then
    ping -c2 -q $DEFAULT_GATEWAY > /dev/null && PING_OK=1
fi

if [ "$PING_OK" = "1" ]; then
    log "Ping $DEFAULT_GATEWAY: OK"
else
    log "Ping $DEFAULT_GATEWAY: ERROR"

    if [ 0`grep Ping $LOG | tail | grep -cE 'ERROR$'` -ge 10 ]
    then
        log "Rebooting"
        sync
	reboot
        exit
    fi

    log "Output of: ip addr"
    ip addr

    log "Output of: ip route"
    ip route

    log "Stopping Network"
    /bin/systemctl daemon-reload
    /bin/systemctl stop networking.service
    killall wpa_supplicant

    log "Reinitialize USB WiFi Stick"
    echo $USB_ID_WLAN0 > /sys/bus/usb/drivers/usb/unbind
    modprobe -rv 8192cu
    sleep 5s
    modprobe -v 8192cu
    sleep 5s
    echo $USB_ID_WLAN0 > /sys/bus/usb/drivers/usb/bind
    sleep 2s

    log "Starting Network"
    /bin/systemctl start networking.service
fi
