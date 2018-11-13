
grep -v 'dns' udhcpd-raspg.conf
grep -e '^nameserver' /etc/resolv.conf | awk '{print "opt\tdns\t",  $2}'



