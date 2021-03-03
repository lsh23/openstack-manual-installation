#!/bin/sh
# this script is based on https://docs.openstack.org/install-guide/launch-instance.html

# load common variable
. ../common-config

# add the compute node to the cell database
/bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

# make provider network
. ./admin-openrc
openstack network create  --share --external \
  --provider-physical-network provider \
  --provider-network-type flat provider

## using gateway, subnet of your provider network
openstack subnet create --network provider \
  --dns-nameserver 8.8.8.8 --gateway $PROVIDER_NETWORK_GATEWAY \
  --subnet-range $PROVIDER_NETWORK_CIDER provider

# make selfservice netowrk
## configure any subnet you want. selfservice network is just a your custom network.
. ./demo-openrc
openstack network create selfservice
openstack subnet create --network selfservice \
  --dns-nameserver 8.8.4.4 --gateway 172.16.1.1 \
  --subnet-range 172.16.1.0/24 selfservice

# connect selfservice to provider (external) using router
. ./demo-openrc
openstack router create router
openstack router add subnet router selfservice
openstack router set router --external-gateway provider

# make nano flavor for test
. ./admin-openrc
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano

# make ssh key
. ./demo-openrc
ssh-keygen -q -N ""<<EOF

EOF

openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey

# open ssh,ping ports of demo default gruop
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default
