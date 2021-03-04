# load common variable
. ./common-config

# configure management network interface  ------------------------------------------
 
cat > /etc/netplan/01-netcfg.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $MANAGEMENT_INTERFACE_NAME:
      addresses: [$MY_IP/24]
      gateway4: $MANAGEMENT_NETWORK_GATEWAY
      dhcp4: no
      nameservers:
        addresses: [8.8.8.8,8.8.4.4]
EOF

netplan apply

# configure provider network interface  ------------------------------------------

sudo apt install ifupdown -y

cat > /etc/network/interfaces << EOF

# The provider network interface
auto $PROVIDER_INTERFACE_NAME
iface $PROVIDER_INTERFACE_NAME inet manual
up ip link set dev \$IFACE up
down ip link set dev \$IFACE down

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


