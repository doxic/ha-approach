#!/bin/bash

# remove network manager
systemctl stop NetworkManager
systemctl disable NetworkManager
yum remove -y NetworkManager*

# delete network files
rm -f /etc/sysconfig/network-scripts/ifcfg-eth1
rm -f /etc/sysconfig/network-scripts/ifcfg-eth2

# write network scripts
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-team0
DEVICE=team0
DEVICETYPE=Team
TEAM_CONFIG='{"runner": {"name": "activebackup"}, "link_watch": {"name": "ethtool"}}'
MTU=1400
BOOTPROTO=none
IPADDR=192.168.100.100
PREFIX=24
IPV4_FAILURE_FATAL=yes
IPV6INIT=no
ONBOOT=yes
EOF


cat << EOF > /etc/sysconfig/network-scripts/ifcfg-team0-eth1
NAME=team0-eth1
DEVICE=eth1
ONBOOT=yes
TEAM_MASTER=team0
DEVICETYPE=TeamPort
MTU=1400
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-team0-eth2
NAME=team0-eth2
DEVICE=eth2
ONBOOT=yes
TEAM_MASTER=team0
DEVICETYPE=TeamPort
MTU=1400
EOF

# Reload network
systemctl restart network
# enable rc.local
cat << EOF > /etc/rc.d/rc.local
#!/bin/sh
ip link set eth1 promisc on
ip link set eth2 promisc on
ip link set team0 promisc on
ip route flush dev eth1
ip route flush dev eth2
export PATH=$PATH:/usr/local/bin
exit 0
EOF

chmod u+x /etc/rc.d/rc.local
systemctl enable rc-local
systemctl start rc-local
/etc/rc.d/rc.local

cp /vagrant/provisioning/runonce.sh /usr/local/bin/pcipVIP
chmod u+x /usr/local/bin/pcipVIP
