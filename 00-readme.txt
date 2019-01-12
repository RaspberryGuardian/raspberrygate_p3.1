
** HOW TO INSTALL

Step 1: Become root.

Step 2: run install.sh

 # ./install.sh

 or

 # bash install.sh


Daemon udhcpd is also installed in this install script.  And
/etc/udhcpd.conf will be updated.  Shell /bin/bash command is required
when you run shell script of this package.


* HOW TO TEST

** Bridge mode

run bridge.sh for bridge mode.

 # ./bridge.sh

** Router mode 

run router-nat for router mode.

 # ./router-nat.sh

eth0 will get IP address from dhcp.
eth1 is 192.168.72.1.

** udhcpd config update

Default DNS servers are google dns server (8.8.8.8 and 8.8.4.4).  If
you want to update dns in your network, use udhcpd-config-update.sh
for update /etc/udhcpd.conf file.

# ./udhcpd-config-update.sh > /etc/udhcpd.conf 


