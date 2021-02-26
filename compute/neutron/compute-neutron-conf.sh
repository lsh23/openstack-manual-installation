cat > /etc/neutron/neutron.conf <<EOF
[DEFAULT]
core_plugin = ml2
transport_url = rabbit://openstack:$RABBIT_PASS@controller
auth_strategy = keystone

[agent]
root_helper = "sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf"


[database]
connection = sqlite:////var/lib/neutron/neutron.sqlite


[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = $NEUTRON_PASS


[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
EOF