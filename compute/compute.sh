#!/bin/sh

# install chrony (NTP) ------------------------------------------

apt install chrony -y

# configure /etc/chrony/chrony.conf
/bin/sh ./compute-chorny.sh

service chrony restart

# install verification
# chronyc sources


# install nova-compute ------------------------------------------

apt install nova-compute -y

# configure /etc/nova/nova.conf
/bin/sh ./nova-compute/compute-nova-conf.sh

# configure /etc/nova/nova-compute.conf 
/bin/sh ./nova-compute/compute-nova-compute-conf.sh

service nova-compute restart


# install neutron-linuxbridge-agent ------------------------------------------

apt install -y neutron-linuxbridge-agent


# configure /etc/neutron/neutron.conf
/bin/sh ./neutron/compute-neutron-conf.sh

# configure /etc/neutron/plugins/ml2/linuxbridge_agent.ini
/bin/sh ./neutron/compute-neutron-linuxbridge_agent-ini.sh

# enable networking bridge support
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
sysctl -p

# configure /etc/nova/nova.conf
/bin/sh ./nova-compute/compute-nova-conf.sh

service nova-compute restart
service neutron-linuxbridge-agent restart