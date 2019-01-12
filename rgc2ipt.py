#!/usr/bin/python

# If you need pyyaml library, then do it.
# % pip install pyyaml
#
# 
#
#


debugmode=0
import yaml
import copy
import os
import argparse

interface_in = 'eth0'
interface_out = 'eth1'
parser = argparse.ArgumentParser(description='Filtering Interface Options')
parser.add_argument('--in-interface' , help='eth0 / eth1 / wlan0 / wlan1')
parser.add_argument('--out-interface', help='eth0 / eth1 / wlan0 / wlan1')
args = parser.parse_args()
if  args.in_interface != None:
	interface_in=args.in_interface
if args.out_interface != None:
	interface_out=args.out_interface

#print("interface in: " + interface_in)
#print("interface out: " + interface_out)


## Value to Integer
def val2int(value):
	if value == None:
		return 0
	if isinstance(value,int) == False:
		return 0
	return value

## Value to String
def val2str(value):
	if value == None:
		return ""
	if isinstance(value,str) == False:
		return ""
	return value

## L2 output
def l2func(entrylist):
	l2=open('l2iptables.txt',mode='w')
	debugmode=val2int(entrylist.get('debug',-1))
	if  debugmode > 0: 
		l2.write('exec 2> /tmp/l2filter_debug.txt\n')
	if entrylist.get('debug'):
		del entrylist['debug']
		
	### L2 Init
	## Flush All Entry 
	l2.write('iptables -F\n')

	## ICMP 
	entrylist.get('icmp','deny')
	icmpSetting=val2str(entrylist.get('icmp','deny'))
	if icmpSetting == 'allow':
		l2.write('iptables -A FORWARD -p icmp -j ACCEPT\n')
	if entrylist.get('icmp'):
		del entrylist['icmp']


	### OTHERS
	for entry  in entrylist:
		if entry != 'default':  # make iptables entry expect default
			l2entry(l2,entry,entrylist[entry])

	## DEFAULT
	entrylist.get('default','deny')
	defaultSetting=val2str(entrylist.get('default','deny'))
	if defaultSetting == 'deny':
		print('L2: default deny')
		l2.write('iptables -A FORWARD -j DROP\n')
	if entrylist.get('default'):
		del entrylist['default']


def l2entry(l2,entry,entrylist):
	entry_str=""
	if type(entry) == int:
		entry_str=str(entry)
	else:
		entry_str=entry

	if type(entrylist) == str:
		if entrylist == 'allow':
			iptables_commandline ='iptables -A FORWARD -p tcp --dport ' + entry_str + '  -j ACCEPT\n'
			l2.write(iptables_commandline)
			iptables_commandline ='iptables -A FORWARD -p tcp --sport ' + entry_str + '  -j ACCEPT\n'
			l2.write(iptables_commandline)
			iptables_commandline ='iptables -A FORWARD -p udp --dport ' + entry_str + '  -j ACCEPT\n'
			l2.write(iptables_commandline)
			iptables_commandline ='iptables -A FORWARD -p udp --sport ' + entry_str + '  -j ACCEPT\n'
			l2.write(iptables_commandline)

		elif entrylist == 'deny':
			iptables_commandline ='iptables -A FORWARD -p tcp --dport ' + entry_str + '  -j DROP\n'
			l2.write(iptables_commandline)
			iptables_commandline ='iptables -A FORWARD -p tcp --sport ' + entry_str + '  -j DROP\n'
			l2.write(iptables_commandline)
			iptables_commandline ='iptables -A FORWARD -p udp --dport ' + entry_str + '  -j DROP\n'
			l2.write(iptables_commandline)
			iptables_commandline ='iptables -A FORWARD -p udp --sport ' + entry_str + '  -j DROP\n'
			l2.write(iptables_commandline)

		else:
			l2.write('#### Ignore Entry ' + entry + ":" + entrylist +"\n")

	if type(entrylist) == dict:
		for subentry in entrylist:
			if subentry != 'tcp' and subentry != 'udp':
				print("Not implement yet: ", entrylist)
				continue
			if entrylist[subentry] == 'allow':
				iptables_commandline= 'iptables -A FORWARD -p '+ subentry + ' --dport ' + entry_str + ' -j ACCEPT\n'
				l2.write(iptables_commandline)
				iptables_commandline= 'iptables -A FORWARD -p '+ subentry + ' --sport ' + entry_str + ' -j ACCEPT\n'
				l2.write(iptables_commandline)
			elif entrylist[subentry] == 'deny':
				iptables_commandline= 'iptables -A FORWARD -p '+ subentry + ' --dport ' + entry_str + ' -j DROP\n'
				l2.write(iptables_commandline)
				iptables_commandline= 'iptables -A FORWARD -p '+ subentry + ' --sport ' + entry_str + ' -j DROP\n'
				l2.write(iptables_commandline)
			else:
				l2.write('#### Ignore Entry ' + entry + ":" + subentry +"\n")


def l3func(entrylist):
	l3=open('l3iptables.txt',mode='w')
	debugmode=val2int(entrylist.get('debug',-1))
	if debugmode > 0: 
		l3.write('exec 2> /tmp/l3filter_debug.txt\n')
	if entrylist.get('debug'):
		del entrylist['debug']

	### L3 Init
	l3.write('iptables -F\n')
	l3.write('iptables -N RASPGATE\n')
	l3.write('iptables -A FORWARD -j RASPGATE\n')

	## ICMP 
	entrylist.get('icmp','deny')
	defaultSetting=val2str(entrylist.get('icmp','deny'))
	if defaultSetting == 'allow':
		l3.write('iptables -A RASPGATE -p icmp -j ACCEPT\n')
	if entrylist.get('icmp'):
		del entrylist['icmp']

	
	for entry  in entrylist: 
		if entry != 'default': ## make entry except default
			l3entry(l3,entry,entrylist[entry])

	## DEFAULT 
	defaultFilter=val2str(entrylist.get('default','deny'))
	if defaultFilter == 'deny':
		print('L3: default deny')
		l3.write('iptables -A RASPGATE -j DROP\n')
	if entrylist.get('default'):
		del entrylist['default']


	## finish

def l3entry(l3,entry,entrylist):
	entry_str=""
	if type(entry) == int:
		entry_str=str(entry)
	else:
		entry_str=entry

	if type(entrylist) == str:
		if entrylist == 'allow':
			iptables_commandline= 'iptables -A RASPGATE -i ' + interface_in + ' -p tcp --dport ' + entry_str + ' -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT\n'
			l3.write(iptables_commandline)
			iptables_commandline= 'iptables -A RASPGATE -i ' + interface_out + '  -p tcp --sport ' + entry_str + ' -m state --state ESTABLISHED,RELATED -j ACCEPT\n'
			l3.write(iptables_commandline)
			iptables_commandline= 'iptables -A RASPGATE -i ' + interface_in + ' -p udp --dport ' + entry_str + ' -j ACCEPT\n'
			l3.write(iptables_commandline)
			iptables_commandline= 'iptables -A RASPGATE -i ' + interface_out + ' -p udp --sport ' + entry_str + ' -j ACCEPT\n'
			l3.write(iptables_commandline)

		elif entrylist == 'deny':
			iptables_commandline= 'iptables -A RASPGATE -i ' + interface_in + ' -p tcp --dport ' + entry_str + ' -j DROP\n'
			l3.write(iptables_commandline)
			iptables_commandline= 'iptables -A RASPGATE -i ' + interface_out + ' -p tcp --sport ' + entry_str + ' -j DROP\n'
			l3.write(iptables_commandline)
			iptables_commandline= 'iptables -A RASPGATE -i ' + interface_in + ' -p udp --dport ' + entry_str + ' -j DROP\n'
			l3.write(iptables_commandline)
			iptables_commandline= 'iptables -A RASPGATE -i ' + interface_out + ' -p udp --sport ' + entry_str + ' -j DROP\n'
			l3.write(iptables_commandline)
		else:
			l3.write('#### Ignore Entry ' + entry + ":" + entrylist +"\n")

	if type(entrylist) == dict:
		for subentry in entrylist:
			if subentry != 'tcp' and subentry != 'udp':
				print("Not implement yet: ", entrylist)
				continue
			if entrylist[subentry] == 'allow':
				iptables_commandline= 'iptables -A RASPGATE -i '+ interface_out + ' -p '+ subentry + ' --dport ' + entry_str + ' -j ACCEPT\n'
				l3.write(iptables_commandline)
				iptables_commandline= 'iptables -A RASPGATE -i ' + interface_in + ' -p '+ subentry + ' --sport ' + entry_str + ' -j ACCEPT\n'
				l3.write(iptables_commandline)
			elif entrylist[subentry] == 'deny':
				iptables_commandline= 'iptables -A RASPGATE -i ' + interface_out + ' -p '+ subentry + ' --dport ' + entry_str + ' -j DROP\n'
				l3.write(iptables_commandline)
				iptables_commandline= 'iptables -A RASPGATE -i ' + interface_in + ' -p '+ subentry + ' --sport ' + entry_str + ' -j DROP\n'
				l3.write(iptables_commandline)
			else:
				l3.write('#### Ignore Entry ' + entry + ":" + subentry +"\n")


#
# Main Body
#

if __name__ == "__main__":

### Read Configuration from rgf.conf
	## A file in current directory is a first choice file.
	if os.path.exists("rgf.conf"):
		with open('rgf.conf') as stream:
			data=yaml.load(stream)
	else:
		### look-up system's configure file
		with open('/opt/raspg/etc/rgf.conf') as stream:
			data=yaml.load(stream)

	l2data = copy.copy(data)
### Call L2
	l2func(l2data)

	l3data = copy.copy(data)
### Call L3
	l3func(l3data)
