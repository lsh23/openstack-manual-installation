cat > /etc/nova/nova.conf <<EOF
[DEFAULT]
lock_path = /var/lock/nova
state_path = /var/lib/nova
transport_url = rabbit://openstack:$RABBIT_PASS@controller
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver


[api]
auth_strategy = keystone


[api_database]
connection = sqlite:////var/lib/nova/nova_api.sqlite

[cells]
enable = False

[database]
connection = sqlite:////var/lib/nova/nova.sqlite



[glance]
api_servers = http://controller:9292


[keystone_authtoken]

auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = $NOVA_PASS


[neutron]

url = http://controller:9696
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = $NEUTRON_PASS


[oslo_concurrency]
lock_path = /var/lib/nova/tmp


[placement]

os_region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = $PLACEMENT_PASS


[vnc]
enabled = True
server_listen = 0.0.0.0
server_proxyclient_address = $MY_IP
novncproxy_base_url = http://$CONTROLLER_M_IP:6080/vnc_auto.html

EOF