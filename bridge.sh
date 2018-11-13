#!/bin/bash

TARGET=eth1
EHTERNET=$(ifconfig | grep $TARGET | awk '{print $1}')


##
## Bridge Script 
##

if [ wlan0$EHTERNET == wlan0 ] ; then
    ## WiFi start
    TARGET=wlan0
    /etc/init.d/hostapd start
fi


ifconfig eth0 down
ifconfig $TARGET down
ifconfig br0 down
brctl addbr br0
brctl addif br0 eth0 $TARGET
brctl show


ifconfig eth0 0.0.0.0 up
ifconfig $TARGET 0.0.0.0 up



modprobe br_netfilter
sysctl -w net.bridge.bridge-nf-call-ip6tables=1
sysctl -w net.bridge.bridge-nf-call-iptables=1
sysctl -w net.bridge.bridge-nf-call-arptables=1

if [ -f $RASPGDIR/etc/rgf.conf ] ; then
    TMPDIR=$(mktemp -d)
    pushd $TMPDIR
    cp $RASPGDIR/etc/rgf.conf .
    $RASPGDIR/bin/rgc2ipt
    bash l2iptables.txt
    popd
    /bin/rm -fr $TMPDIR
fi


exit 0
