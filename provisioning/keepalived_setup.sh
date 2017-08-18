#
# keepalived
#

# Install keepalived
yum install -y keepalived

# keepalived.conf
cat << 'EOF' > /etc/keepalived/keepalived.conf
# vim /etc/keepalived/keepalived.conf
vrrp_script chk_pci_proxy_tcp
{
  script "test -f /var/run/pci-proxy-tcp/pci-proxy-tcp.pid"
  interval 10       # Run script every i seconds
  fall 3            # If script returns non-zero f times in succession, enter FAULT state
  rise 3            # If script returns zero r times in succession, exit FAULT state
}

vrrp_script chk_tcp_prod1_port
{
  script "</dev/tcp/127.0.0.1/23000" # connects and exits
  interval 10       # Run script every i seconds
  fall 3            # If script returns non-zero f times in succession, enter FAULT state
  rise 3            # If script returns zero r times in succession, exit FAULT state
}

vrrp_script chk_tcp_prod2_port
{
  script "</dev/tcp/127.0.0.1/23001" # connects and exits
  interval 10       # Run script every i seconds
  rise 3            # If script returns zero r times in succession, exit FAULT state
  fall 3            # If script returns non-zero f times in succession, enter FAULT state
}

vrrp_instance vrrp_approach
{
  state BACKUP
  nopreempt
  interface team0
  virtual_router_id 1
  unicast_src_ip 192.168.100.100
  unicast_peer
  {
    192.168.100.200
  }
  priority 101
  advert_int 5

  authentication
  {
    auth_type PASS
    auth_pass pass
  }

  virtual_ipaddress
  {
    192.168.100.90 dev team0
  }

  virtual_routes
  {
  }

  track_interface
  {
    team0
  }

  track_script
  {
  }

  notify /usr/local/bin/keepalived_notify_vrrp_approach.sh
}
EOF


cat << 'EOF' > /usr/local/bin/keepalived_notify_vrrp_approach.sh
#!/bin/bash
TYPE=$1
NAME=$2
STATE=$3

echo "vrrp_approach on $HOSTNAME has transitioned to state $(tput bold)$STATE$(tput sgr0)" | wall
exit 0
EOF
chmod u+x /usr/local/bin/keepalived_notify_vrrp_approach.sh
