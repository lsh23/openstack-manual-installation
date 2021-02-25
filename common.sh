# config and export common configurations

export PROVIDER_INTERFACE_NAME=eth0
export MANAGEMENT_NETWORK_CIDER=10.0.0.0/24
export CONTROLLER_M_IP=10.0.0.11
export MY_IP=10.0.0.31

export RABBIT_PASS=1234
export ADMIN_PASS=1234

export NOVA_PASS=1234
export NEUTRON_PASS=1234
export GLANCE_PASS=1234

export METADATA_SECRET=1234

export GLANCE_DBPASS=1234
export NEUTRON_DBPASS=1234
export NOVA_DBPASS=1234
export PLACEMENT_PASS=1234


# make provider network interface unnumbered

cat > /etc/netplan/01-netcfg.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
EOF

service netplan apply

sudo apt install ifupdown -y

cat >  /etc/network/interfaces << EOF

# The provider network interface
auto $PROVIDER_INTERFACE_NAME
iface $PROVIDER_INTERFACE_NAME inet manual
up ip link set dev $IFACE up
down ip link set dev $IFACE down

EOF

service networking restart

# add domains

vi /etc/hosts # append

$CONTROLLER_M_IP controller
$COMPUTE_M_IP compute

# pakages update & install openstack client

apt-get \
        -o Dpkg::Options::="--force-confnew" \
        --force-yes \
        -fuy \
        dist-upgrade


apt install python-openstackclient -y


