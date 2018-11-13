#!/bin/bash

if [ -d /opt/raspg ] ; then
    echo "Update raspg utils"
else
    echo "Making /opt/raspg directory"
    if [ -d  /opt ] ; then
	mkdir /opt/raspg 
	echo '/opt/raspg directory is created'
	mkdir /opt/raspg/bin
	mkdir /opt/raspg/lib
	mkdir /opt/raspg/etc
    else
	echo 'Raspberry Pi/ Rasbian ????'
	exit 0
    fi
fi

if [ ! -x /usr/bin/bc ] ; then
    apt-get install bc
fi
if [ ! -x /sbin/brctl ] ; then
    apt-get install bridge-utils
fi
 
if  [ ! -x  /usr/sbin/udhcpd ] ; then
    apt-get install udhcpd
fi


if [ -f udhcpd.conf.org ] ; then
    echo  ""
else
    echo  "First installed and backup original udhcpd.conf"
    mv /etc/udhcpd.conf /etc/udhcpd.conf.org
fi

echo "Renew udhcpd.conf"
cp udhcpd-raspg.conf /etc/udhcpd.conf
cp udhcpd-raspg.conf /opt/raspg/etc


if  [ ! -x  /usr/sbin/hostapd ] ; then
    apt-get install hostapd
    echo 'DAEMON_CONF=/etc/hostapd.conf' >> /etc/default/hostapd
fi

if [ -f hostapd.conf.org ] ; then
    echo  ""
else
    if [ -f /etc/hostapd.conf ] ; then
	echo  "First installed and backup original hostapd.conf"
	mv /etc/hostapd.conf /etc/hostapd.conf.org
    fi
fi

cp hostapd-raspg.conf /etc/hostapd.conf
cp hostapd-raspg.conf /opt/raspg/etc



install bridge.sh /opt/raspg/bin
install router-nat.sh /opt/raspg/bin
install config-update.sh /opt/raspg/bin
install hostapd-config-update.sh /opt/raspg/bin

#
#

bash install-py.sh
install rgc2ipt.py /opt/raspg/bin/rgc2ipt




if [ -f /opt/raspg/bin/config-update.sh ] ; then
    echo 'Copy raspg into /etc/init.d/'
    install raspg_initd /etc/init.d/raspg

else
    echo 'Install Error... 1'
    exit 1
fi

## Sometime command insserv is not found.
if  [  -x  /usr/sbin/update-rc.d ] ; then
    ## old fashion
    /usr/sbin/update-rc.d raspg defaults

    ## DO NOT RUN hostapd BY DEFAULTS
    /usr/sbin/update-rc.d hostapd disable 
else
    ## newer style
    /usr/sbin/insserv --default raspg
    /usr/sbin/insserv --remove hostapd
fi
