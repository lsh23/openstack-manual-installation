cat > /etc/neutron/plugins/ml2/ml2_conf.ini << EOF
[DEFAULT]


[ml2]
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = linuxbridge,l2population
extension_drivers = port_security


[ml2_type_flat]
flat_networks = provider


[ml2_type_vxlan]
vni_ranges = 1:1000


[securitygroup]
enable_ipset = true
EOF