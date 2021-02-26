cat > /etc/neutron/plugins/ml2/linuxbridge_agent.ini << EOF
[DEFAULT]

[linux_bridge]
physical_interface_mappings = provider:$PROVIDER_INTERFACE_NAME



[securitygroup]
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver


[vxlan]
enable_vxlan = true
local_ip = $CONTROLLER_M_IP
l2_population = true
EOF
