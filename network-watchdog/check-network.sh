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

FFMUC_OFFLOADER_V6=fe80:0:0:0:32b5:c2ff:fee3:58%wlan0

PING_V6_OK=0
PING_V4_OK=0
ping6 -c2 -q $FFMUC_OFFLOADER_V6 > /dev/null && PING_V6_OK=1
ping -c2 -q $DEFAULT_GATEWAY > /dev/null && PING_V4_OK=1

if [ "$PING_V6_OK" = "1" ]; then
    log "Ping $FFMUC_OFFLOADER_V6: OK"
else
    log "Ping $FFMUC_OFFLOADER_V6: ERROR"

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

    log "Output of: iwconfig wlan0"
    iwconfig wlan0
    log "Output of: iwlist wlan0 scanning | grep SSID"
    iwlist wlan0 scanning | grep SSID

    log "Stopping Network"
    /bin/systemctl daemon-reload
    /bin/systemctl stop networking.service
    /bin/systemctl stop dhcpcd
    pkill wpa_supplicant
    pkill dhcpcd

    if [ 0`grep Ping $LOG | tail -n3 | grep -cE 'ERROR$'` -ge 3 ]
    then
	    log "Reinitialize USB WiFi Stick"
	    echo $USB_ID_WLAN0 > /sys/bus/usb/drivers/usb/unbind
	    modprobe -rv 8192cu
	    sleep 5s
	    modprobe -v 8192cu
	    sleep 5s
	    echo $USB_ID_WLAN0 > /sys/bus/usb/drivers/usb/bind
	    sleep 2s
    fi

    log "Starting Network"
    /bin/systemctl start dhcpcd
    /bin/systemctl start networking.service
fi
