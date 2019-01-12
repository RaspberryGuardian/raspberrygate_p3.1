#!/bin/bash

if [ x$RASPGDIR == 'x' ]; then
    RASPGDIR=/opt/raspg
fi

TARGET=eth1
EHTERNET=$(ifconfig | grep $TARGET | awk '{print $1}')


##
## Bridge Script 
##

if [ wlan0$EHTERNET == wlan0 ] ; then
    ## WiFi or NOT
    TARGET=wlan0
fi

## Make Bridge 0 now
brctl addbr br0
ifconfig br0 up

### ETH0
ifconfig eth0 down
ifconfig eth0 0.0.0.0 up
brctl addif br0 eth0 

### TARGET

ifconfig $TARGET down

if [ $TARGET == wlan0 ] ; then
    /etc/init.d/hostapd start
fi

ifconfig $TARGET 0.0.0.0 up
brctl addif br0 $TARGET
brctl show


modprobe br_netfilter
##sysctl -w net.bridge.bridge-nf-call-ip6tables=1
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
