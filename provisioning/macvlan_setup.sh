
#
# TEAMD
#
cat << 'EOF' > ~/teamd.conf
{
    "device":    "team0",
    "runner":    {"name": "activebackup"},
    "link_watch":    {"name": "ethtool"},
    "ports":    {
        "eth1": {
            "prio": -10,
            "sticky": true
        },
        "eth2": {
            "prio": 100
        }
    }
}
EOF

#find devices, set them down
ip link show
ip link set down eth1
ip link set down eth2

#create team
teamd -g -f ~/teamd.conf -d
#-g option is for debug messages
#-f option is to specify the configuration file to load
#-d option is to make the process run as a daemon after startup

#check status
teamdctl team0 state

#add host ip
ip addr add 192.168.100.100/24 dev team0

#active interface
ip link set dev team0 up


# CLEANUP
# take down
ip link set dev team0 down
# kill teaming
teamd -t team0 -k







# Revert
ip link set dev mv1 down
ip addr del 192.168.100.200/24 dev mv1

ip link delete mv1



#
# PERSISTENT
#

rm -f /etc/sysconfig/network-scripts/ifcfg-eth1

# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Networking_Guide/sec-Configure_a_Network_Team_Using-the_Command_Line.html#sec-Creating_a_Network_Team_Using_ifcfg_Files
IF1=eth1
IF2=eth2

#turn on promiscous mode VIRTUALBOX
# turn on promiscous mode
ip link set dev $IF1 promisc on
ip link set dev $IF2 promisc on
ip link set team0 promisc on

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-team0
DEVICE=team0
DEVICETYPE=Team
TEAM_CONFIG='{"runner": {"name": "activebackup"}, "link_watch": {"name": "ethtool"}}'
MTU=1400
BOOTPROTO=none
IPADDR=192.168.100.101
PREFIX=24
DNS1=192.168.77.40
DNS2=192.168.77.50
IPV4_FAILURE_FATAL=yes
IPV6INIT=no
PROMISC=yes
ONBOOT=yes
EOF
 
 
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-team0-$IF1
HWADDR=${MAC1:-$(ip link show dev $IF1 | grep -Po 'ether \K[^ ]*' | tr /a-z/ /A-Z/)}
NAME=team0-$IF1
DEVICE=$IF1
ONBOOT=yes
PROMISC=yes
TEAM_MASTER=team0
DEVICETYPE=TeamPort
MTU=1400
EOF
 
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-team0-$IF2
HWADDR=${MAC2:-$(ip link show dev $IF2 | grep -Po 'ether \K[^ ]*' | tr /a-z/ /A-Z/)}
NAME=team0-$IF2
DEVICE=$IF2
ONBOOT=yes
PROMISC=yes
TEAM_MASTER=team0
DEVICETYPE=TeamPort
MTU=1400
EOF

#
# SWITCH
#
cat << EOF > /usr/local/bin/switchVIP.sh
#!/bin/bash
#
# switchVIP.sh       Bring virtual interfaces up/down
#
# See how we were called.
case "$1" in
  enable)
  
  disable)
  
  *)
	echo $"Usage: $0 {start|stop|status|restart|reload|force-reload}"
	exit 2
EOF


until nc -vzw 2 $host 22; do sleep 2; done



PINGSTATE=0;
while [ $PINGSTATE -eq "0" ]; 
   do sleep 1; ping -q -c 1 -w 1 192.168.100.200 &>/dev/null; PINGSTATE=$?; echo "PING 192.168.100.200 successful. Waiting..." $PINGSTATE; 
done

ip addr add 192.168.100.200/24 dev mv1
ping -I team0 192.168.100.1

# detect existing IP in network
# https://www.cyberciti.biz/faq/linux-duplicate-address-detection-with-arping/
arping -I team0 -c 3 192.168.100.99
#-I eth0 : Specify network interface i.e. name of network device where to send ARP REQUEST packets. This option is required.
#-c 3 : Stop after sending 3 ARP REQUEST packets


#tcpdump
#-vvv Maximum verbosity
#-s Snaplength (0 captures full packets)
#-S disable relative sequence numbers (memory leak)
#-nn Do not resolve host or service names
#-i Interface - can be ifname or vlan name
#-w Write output to file
#-W filecound
#-e print MAC layer addresses
sudo tcpdump -vvv -s 0 -e -nni eth1 'arp or icmp'

#
# MACVLAN
#

# Create macvlan device
# https://unix.stackexchange.com/questions/21841/make-some-virtual-mac-address?rq=1
sudo ip link add link team0 address 06:00:01:00:00:99 vip99 type macvlan mode bridge
#active interface
sudo ip link set dev vip99 up

# https://www.linux.com/learn/replacing-ifconfig-ip
# add ip
sudo ip addr add 192.168.100.99/24 dev vip99

# Send a Gratuitous ARPs Requests
#-A : ARP reply
#-C 4: Send it four times
#-I eth1: Use eth1 interface
arping -c 4 -A -I vip99 192.168.100.99

# ping gateway
ping -I vip99 192.168.100.1

# remove ip
sudo ip addr del 192.168.100.99/24 dev vip99

# Disable ARP for VIP
# https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt
arp_filter 1
arp_notify 1
echo 1 > /proc/sys/net/ipv4/conf/all/arp_filter
echo 1 > /proc/sys/net/ipv4/conf/all/arp_notify

echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce