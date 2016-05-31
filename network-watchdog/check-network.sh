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

network_stop() {
    /bin/systemctl stop dhcpcd
    for interface in $INTERFACES
    do
        log "Stopping interface $interface"
        ifdown $interface
    done
}

network_start() {
    for interface in $INTERFACES
    do
        log "Starting interface $interface"
        ifup $interface
    done
    /bin/systemctl start dhcpcd
}

print_current_network_status() {
    log "Output of: ip addr"
    ip addr

    log "Output of: ip route"
    ip route

    log "Output of: ip -6 route"
    ip -6 route

    for interface in $INTERFACES
    do
        log "Output of: iwconfig $interface"
        iwconfig $interface

        log "Output of: iwlist $interface scanning | grep SSID"
        iwlist $interface scanning | grep SSID
    done
}

check_modulo() {
    local counter=$1
    local limit=$2
    [ $counter -gt 0 ] && (( $counter % $limit == 0 ))
}

# Locking
[ -e `dirname $0`/../global/bash-locking.inc.sh ] && . `dirname $0`/../global/bash-locking.inc.sh

#### 
logrotate

exec >> $LOG
exec 2>> $LOG

DEFAULT_GATEWAY_V4=$(ip -4 route show default | head -n1 | awk '/^default/ {print $3}')
DEFAULT_GATEWAY_V6=$(ip -6 route show default | head -n1 | awk '/^default/ {print $3"%"$5}')

IPV4_PING_DEST=$DEFAULT_GATEWAY_V4
IPV6_PING_DEST=$DEFAULT_GATEWAY_V6

IPV4_ENABLED=0
IPV6_ENABLED=0

PING_LIMIT_NET_RESTART=5
PING_LIMIT_REBOOT=60
PING_LIMIT_WATCHDOG_FAIL=70

INTERFACES="wlan0"

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

# warning for deprecated variables
for deprecated in PING_LIMIT_1 PING_LIMIT_3 PING_LIMIT_4; do
    log "$deprecated deprecated! Default value will be used if variable was renamed"
done

# reboot detection:
CURRENT_STATUS_UPTIME=$(cut -d"." -f1 /proc/uptime)

if [ -z $STATUS_UPTIME ] || [ $CURRENT_STATUS_UPTIME -lt $STATUS_UPTIME ]; then
    STATUS_FAILED_V4=0
    STATUS_FAILED_V6=0
fi

STATUS_UPTIME=$CURRENT_STATUS_UPTIME

# save variables to file which start with $SAVE_VARIABLE_PREFIX
trap 'save_variables > $STATUS_FILE' EXIT

# v6
if [ $IPV6_ENABLED -eq 0 ]; then
    # set it to zero for easier error conditions
    STATUS_FAILED_V6=0
else
    if [ "$IPV6_PING_DEST" != "" ] && ping6 -c5 -q $IPV6_PING_DEST > /dev/null; then
        STATUS_FAILED_V6=0
    else
        STATUS_FAILED_V6=$(( ${STATUS_FAILED_V6:-0} + 1 ))
    fi
    
    if [ "$STATUS_FAILED_V6" -eq 0 ]; then
        log "Ping v6 $IPV6_PING_DEST: OK"
    else
        log "Ping v6 ${IPV6_PING_DEST:-no v6 address to ping}: ERROR"
    fi
fi
# v4
if [ $IPV4_ENABLED -eq 0 ]; then
    # set it to zero for easier error conditions
    STATUS_FAILED_V4=0
else
    if [ "$IPV4_PING_DEST" != "" ] && ping -c5 -q $IPV4_PING_DEST > /dev/null; then
        STATUS_FAILED_V4=0
    else
        STATUS_FAILED_V4=$(( ${STATUS_FAILED_V4:-0} + 1 ))
    fi
    
    if [ "$STATUS_FAILED_V4" -eq 0 ]; then
        log "Ping v4 $IPV4_PING_DEST: OK"
    else
        log "Ping v4 ${IPV4_PING_DEST:-no v4 address to ping}: ERROR"
    fi
fi

if [ $IPV4_ENABLED -eq 1 ] || [ $IPV6_ENABLED -eq 1 ]; then
    if [ $IPV6_ENABLED -eq 1 ] && check_modulo $STATUS_FAILED_V6 $PING_LIMIT_WATCHDOG_FAIL; then
        log "exiting with error code for watchdog"
        exit 1
    elif [ $IPV6_ENABLED -eq 1 ] && check_modulo $STATUS_FAILED_V6 $PING_LIMIT_REBOOT; then
        print_current_network_status
        do_reboot
    elif [ $IPV6_ENABLED -eq 0 ] && [ $IPV4_ENABLED -eq 1 ] && check_modulo $STATUS_FAILED_V4 $PING_LIMIT_REBOOT; then
        print_current_network_status
        do_reboot
    elif check_modulo $STATUS_FAILED_V4 $PING_LIMIT_NET_RESTART || 
        check_modulo $STATUS_FAILED_V6 $PING_LIMIT_NET_RESTART; then
        print_current_network_status
        network_stop
        network_start
    fi
fi

exit 0
