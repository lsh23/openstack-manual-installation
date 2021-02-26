cat > /etc/neutron/dhcp_agent.ini << EOF
[DEFAULT]

interface_driver = linuxbridge
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
EOF

