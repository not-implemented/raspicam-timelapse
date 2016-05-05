#!/bin/sh

. `dirname $0`/../config/interfaces-post-up.conf || exit 1

ip route del default via $stick_gw_ip dev $stick_interface

ip route add $stick_net dev $stick_interface src $stick_local_ip table 1
ip route add default via $stick_gw_ip dev $stick_interface table 1

ip rule add from $stick_local_ip/32 table 1
ip rule add to $stick_local_ip/32 table 1
