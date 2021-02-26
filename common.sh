# load common variable
. ./common-config

# make provider network interface unnumbered ------------------------------------------
 
cat > /etc/netplan/01-netcfg.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
EOF

netplan apply

sudo apt install ifupdown -y

cat > /etc/network/interfaces << EOF

# The provider network interface
auto $PROVIDER_INTERFACE_NAME
iface $PROVIDER_INTERFACE_NAME inet manual
up ip link set dev $IFACE up
down ip link set dev $IFACE down

EOF

service networking restart

# add domains ------------------------------------------

echo $CONTROLLER_M_IP controller >> /etc/hosts
echo $COMPUTE_M_IP compute >> /etc/hosts

# pakages update & install openstack client ------------------------------------------

apt-get \
        -o Dpkg::Options::="--force-confnew" \
        --force-yes \
        -fuy \
        dist-upgrade


apt install python-openstackclient -y


