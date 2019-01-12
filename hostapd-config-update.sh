#!/bin/bash

umask 077
RGCONF=/opt/raspg/etc/raspg.conf
TEMPLATE=/opt/raspg/etc/hostapd-raspg.conf
HCONF=/etc/hostapd.conf

if [ $RGCONF -ot $HCONF ] ; then
    ## No nessesary to update hostapd.conf password and ssid
    exit 0
fi

SSID=$(grep -e '^\s*SSID:\s'  $RGCONF | awk '{print $2}' ) 
PW=$(grep -e '^\s*PW:\s'  $RGCONF | awk '{print $2}' )

if [ x$SSID == x -o x$PW == x ] ; then
    # NO SSID AND/OR NO PASSWORD IN CONFIG FILE
    exit 0
fi
   
if [ -f $HCONF ] ; then
    # BACKUP /etc/hostapd.conf
    mv $HCONF /etc/hostapd.conf.bak
    TEMPLATE=/etc/hostapd.conf.bak
fi

grep -v -e wpa_passphrase= -e  ssid=  $TEMPLATE > $HCONF
echo "ssid=$SSID" >> $HCONF
echo "wpa_passphrase=$PW" >> $HCONF





