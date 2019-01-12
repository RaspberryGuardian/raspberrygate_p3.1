#!/bin/bash

if [ x$RASPGDIR == 'x' ]; then
    RASPGDIR=/opt/raspg
fi

iptables -F
iptables -t nat -F
iptables -X

modprobe iptable_nat
echo 1 > /proc/sys/net/ipv4/ip_forward

TARGET=eth1
#EHTERNET=$(ifconfig | grep $TARGET | awk '{print $1}')
ifconfig | grep $TARGET > /dev/null ; result=$? 
if [ $result -ne 0 ] ; then
    TARGET=wlan0
    /etc/init.d/hostapd start    
fi


ip addr flush dev eth0 
ifconfig eth0 down
ip addr flush dev $TARGET 
ifconfig $TARGET down

#
# Check raspg.conf
#


## default address networkaddress and mask
SETADDRESS=192.168.72.1
NETWORKADDRESS=192.167.72.0/24
mask=24

if [ -f $RASPGDIR/etc/raspg.conf ] ; then
    NETWORKADDRESS=$(grep NetworkAddress: $RASPGDIR/etc/raspg.conf | awk '{print $2}')
    SETADDRESS=$(echo $NETWORKADDRESS | sed  -e 's/\// /'| awk '{print $1}' | sed -e 's/\.0$/.1/')
    mask=$(echo $NETWORKADDRESS | sed -e 's/\// /' | awk '{print $2}')
else
    echo 'RG: Not found: ' $RASPGDIR/etc/raspg.conf
fi

SETMASK=$((echo "n=$mask" ; echo 't=32 - n' ; echo 'a=(2^n -1)*2^t' ; echo 'print b0=(a / 2^24) % 2^8,".",(a / 2^16) % 2^8,".",(a / 2^8) % 2^8,".",a % 2^8' ) | bc )


CONF=/etc/udhcpd.conf

mv  $CONF  ${CONF}.0
echo '# Raspberry Gate Config' > $CONF
(echo -n '#' ; date ) >> $CONF
echo -n 'start   ' >> $CONF
echo $SETADDRESS | sed -e 's/\.1$/.33/' >> $CONF
echo -n 'end     ' >> $CONF
echo $SETADDRESS | sed -e 's/\.1$/.191/' >> $CONF
echo "interface	$TARGET" >> $CONF
echo 'opt	dns	8.8.8.8 8.8.4.4' >> $CONF
echo  'opt subnet  ' $SETMASK >> $CONF
echo -n 'opt router  ' >> $CONF
echo $SETADDRESS | sed -e 's/\.1$/.1/' >> $CONF


## GET WAN side ip address 
dhclient eth0

ifconfig $TARGET $SETADDRESS netmask $SETMASK
iptables --append FORWARD --in-interface $TARGET --out-interface eth0 --source $NETWORKADDRESS --jump ACCEPT
iptables --table nat --append POSTROUTING --out-interface eth0 --jump MASQUERADE


/usr/sbin/udhcpd 

##
## For router filter
##


if [ -f $RASPGDIR/etc/rgf.conf ] ; then
    TMPDIR=$(mktemp -d)
    pushd $TMPDIR
    cp $RASPGDIR/etc/rgf.conf .
    $RASPGDIR/bin/rgc2ipt --out-interface $TARGET --in-interface eth0
    bash l3iptables.txt
    popd
    /bin/rm -fr $TMPDIR
fi

exit 0
