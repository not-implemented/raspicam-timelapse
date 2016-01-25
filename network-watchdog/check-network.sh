#!/bin/bash

[ -e `dirname $0`/../global/global.inc.sh ] && . `dirname $0`/../global/global.inc.sh

USB_ID_WLAN0="1-1.3"
STATUS_FILE=/home/pi/raspicam-timelapse/config/last_status.inc.sh
CONFIG_FILE=/home/pi/raspicam-timelapse/config/check-network.conf
SAVE_VARIABLE_PREFIX=STATUS_

do_reboot() {
    log "Rebooting"
    sync
    /bin/systemctl reboot
}

usb_reset() {
    log "Reinitialize USB WiFi Stick"
    echo $USB_ID_WLAN0 > /sys/bus/usb/drivers/usb/unbind
    modprobe -rv 8192cu
    sleep 5s
    modprobe -v 8192cu
    sleep 5s
    echo $USB_ID_WLAN0 > /sys/bus/usb/drivers/usb/bind
    sleep 2s
}

dhcpd_restart() {
    /bin/systemctl restart dhcpcd
}

network_stop() {
    log "Stopping Network"
    /bin/systemctl daemon-reload
    /bin/systemctl stop networking.service
    /bin/systemctl stop dhcpcd
    pkill wpa_supplicant
    pkill dhcpcd
}

network_start() {
    log "Starting Network"
    /bin/systemctl start dhcpcd
    /bin/systemctl start networking.service
}

print_current_network_status() {
    log "Output of: ip addr"
    ip addr

    log "Output of: ip route"
    ip route

    log "Output of: iwconfig wlan0"
    iwconfig wlan0

    log "Output of: iwlist wlan0 scanning | grep SSID"
    iwlist wlan0 scanning | grep SSID
}

#### 
logrotate

exec >> $LOG
exec 2>> $LOG

DEFAULT_GATEWAY_V4=$(ip -4 route show default | awk '/^default/ {print $3}')
DEFAULT_GATEWAY_V6=$(ip -6 route show default | awk '/^default/ {print $3"%"$5}')

IPV4_PING_DEST=$DEFAULT_GATEWAY_V4
IPV6_PING_DEST=$DEFAULT_GATEWAY_V6

# load config file
if [ -e $CONFIG_FILE ]
then
    . $CONFIG_FILE
fi

# load status file
if [ -e $STATUS_FILE ]
then
    . $STATUS_FILE
fi

# v6
if [ "$IPV6_PING_DEST" != "" ] && ping6 -c5 -q $IPV6_PING_DEST > /dev/null; then
    STATUS_FAILED_V6=0
else
    STATUS_FAILED_V6=$(( ${STATUS_FAILED_V6:-0} + 1 ))
fi
# v4
if [ "$IPV4_PING_DEST" != "" ] && ping -c5 -q $IPV4_PING_DEST > /dev/null; then
    STATUS_FAILED_V4=0
else
     STATUS_FAILED_V4=$(( ${STATUS_FAILED_V4:-0} + 1 ))
fi

if [ "$STATUS_FAILED_V6" -eq 0 ]; then
    log "Ping v6 $IPV6_PING_DEST: OK"
else
    log "Ping v6 ${IPV6_PING_DEST:-no v6 address to ping}: ERROR"
fi

if [ "$STATUS_FAILED_V4" -eq 0 ]; then
    log "Ping v4 $IPV4_PING_DEST OK"
else
    log "Ping v4 ${IPV4_PING_DEST:-no v4 address to ping}: ERROR"
fi

if [ $STATUS_FAILED_V4 -ge 1 -a $STATUS_FAILED_V6 -eq 0 ]; then
    print_current_network_status
    dhcpd_restart
elif [ $STATUS_FAILED_V6 -ge 1 ]; then
    print_current_network_status
    network_stop
    [ $STATUS_FAILED_V6 -ge 3 ] && usb_reset
    network_start
elif [ $STATUS_FAILED_V6 -ge 10 ]; then
    print_current_network_status
    do_reboot && exit
fi

# save variables to file wich start with $SAVE_VARIABLE_PREFIX
save_variables > $STATUS_FILE
