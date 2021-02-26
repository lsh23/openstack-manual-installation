cat > /etc/neutron/metadata_agent.ini << EOF
[DEFAULT]
nova_metadata_host = controller
metadata_proxy_shared_secret = $METADATA_SECRET
EOF