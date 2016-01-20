#!/bin/bash

LOG=/home/pi/capture/check-network.log
USB_ID_WLAN0="1-1.3"
STATUS_FILE=/home/pi/raspicam-timelapse/config/last_status.inc.sh
CONFIG_FILE=/home/pi/raspicam-timelapse/config/check-network.conf
SAVE_VARIABLE_PREFIX=STATUS_

save_variables() {
    set | grep ^$SAVE_VARIABLE_PREFIX
}

show_variables() {
    save_variables | while read line; do
      echo $1 $line
    done
}

log() {
    echo "$(date --rfc-3339=seconds): $*"
}

logrotate() {
    log_size=`stat --format="%s" $LOG`

    if [ $log_size -gt $((100*1024)) ]
    then
        mv $LOG $LOG.old
    fi
}

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

count_error_lines() {
    first_grep_string="$@"
    count=0
    # use fifo so we don't have to use a subshell
    fifo=/tmp/errorlines.fifo
    mkfifo $fifo
    exec 3<> $fifo
    # limit to 100 lines we search string
    # reverse it since "read" reads from top to bottom but we want to count from bottom to top
    tail -n 100 $LOG | grep "$first_grep_string" | tac > $fifo
    while read -u3 -t1 line
    do
        # break if we don't find pattern
        echo "$line" | grep -qE 'ERROR$' && let count++ || break
    done < $fifo
    # cleanup
    exec 3>&-
    rm $fifo
    echo  $cnt
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
