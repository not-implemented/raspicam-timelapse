#!/bin/sh

. `dirname $0`/../config/interfaces-post-up.conf || exit 1

#ip route del default via $stick_gw_ip dev $stick_interface
case $1 in
    down)
       action="del"
        ;;
     up|*)
        action="add"
        ;;
esac

ip route $action $stick_net dev $stick_interface src $stick_local_ip table 1
ip route $action default via $stick_gw_ip dev $stick_interface table 1

ip rule $action from $stick_local_ip/32 table 1
ip rule $action to $stick_local_ip/32 table 1

