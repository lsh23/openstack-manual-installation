#!/bin/sh

# load common variable
. ../common-config

# install chrony (NTP) ------------------------------------------

apt install chrony -y

# configure /etc/chrony/chrony.conf
/bin/sh ./neutron-chrony-conf.sh

service chrony restart

# install verification
# chronyc sources

# install neutron ------------------------------------------

apt install -y neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent


# configure the /etc/neutron/neutron.conf 
/bin/sh ./neutron/controller-neutron-conf.sh

# configure /etc/neutron/plugins/ml2/ml2_conf.ini 
/bin/sh ./neutron/controller-neutron-ml2_conf-ini.sh

# configure /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
/bin/sh ./neutron/controller-neutron-linuxbridge_agent-ini.sh

# enable networking bridge support
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
sysctl -p

# configure /etc/neutron/l3_agent.ini 
/bin/sh ./neutron/controller-neutron-l3_agent-ini.sh

# configure /etc/neutron/dhcp_agent.ini
/bin/sh ./neutron/controller-neutron-dhcp_agent-ini.sh

# configure /etc/neutron/metadata_agent.ini 
/bin/sh ./neutron/controller-neutron-metadata_agent-ini.sh

/bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart