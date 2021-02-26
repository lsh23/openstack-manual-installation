#!/bin/sh

# load common variable
. ../common-config

# install chrony (NTP) ------------------------------------------

apt install chrony -y

# configrue /etc/chrony/chrony.conf
echo allow $MANAGEMENT_NETWORK_CIDER >> /etc/chrony/chrony.conf

service chrony restart

## install verify
# chronyc sources


# install database ------------------------------------------

apt install mariadb-server python-pymysql -y

# configure /etc/mysql/mariadb.conf.d/99-openstack.cnf
cat > /etc/mysql/mariadb.conf.d/99-openstack.cnf << EOF
[mysqld]
bind-address = $CONTROLLER_M_IP

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

service mysql restart

# mysql setting
mysql_secure_installation << EOF
$UBUNTU_ROOT_PASS
y
$DB_ROOT_PASS
$DB_ROOT_PASS




EOF



# install rabbitmq ------------------------------------------

apt install rabbitmq-server -y

rabbitmqctl add_user openstack $RABBIT_PASS

rabbitmqctl set_permissions openstack ".*" ".*" ".*"


# install memcached ------------------------------------------

apt install memcached python-memcache -y

# configure /etc/memcached.conf
/bin/sh ./controller-memcache-conf.sh

service memcached restart


# install etcd ------------------------------------------

#sudo add-apt-repository universe 
apt install etcd -y

# configure /etc/default/etcd

cat << EOT >>  /etc/default/etcd 

ETCD_NAME="controller"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER="controller=http://$CONTROLLER_M_IP:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$CONTROLLER_M_IP:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://$CONTROLLER_M_IP:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://$CONTROLLER_M_IP:2379"

EOT

systemctl enable etcd
systemctl restart etcd


# install keystone ------------------------------------------

# configure keystone db
mysql <<EOF
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY '$KEYSTONE_DBPASS';
EOF


apt install keystone  apache2 libapache2-mod-wsgi -y

# configure /etc/keystone/keystone.conf
/bin/sh ./keystone/controller-keystone-conf.sh

/bin/sh -c "keystone-manage db_sync" keystone

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
#
keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

# /etc/apache2/apache2.conf #append
echo "ServerName controller" >> /etc/apache2/apache2.conf

service apache2 restart

export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3

openstack domain create --description "An Example Domain" example
openstack project create --domain default \
  --description "Service Project" service

openstack project create --domain default \
  --description "Demo Project" demo

openstack user create --domain default \
  --password $DEMO_PASS demo

openstack role create user

openstack role add --project demo --user demo user


cat > admin-openrc << EOF
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF

cat > demo-openrc << EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

# install verify
# unset OS_AUTH_URL OS_PASSWORD
 
# openstack --os-auth-url http://controller:5000/v3 \
#   --os-project-domain-name Default --os-user-domain-name Default \
#   --os-project-name admin --os-username admin token issue


# install horizon ------------------------------------------

apt install python-pip -y

pip install Django==1.11

apt install openstack-dashboard -y

# configrue /etc/openstack-dashboard/local_settings.py
/bin/sh ./horizon/controller-horizon-local_settings.sh

systemctl reload apache2.service

# install glance ------------------------------------------

mysql -u root -p$DB_ROOT_PASS<<EOF
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
  IDENTIFIED BY '$GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
  IDENTIFIED BY '$GLANCE_DBPASS';
EOF

. ./admin-openrc

openstack user create --domain default --password $GLANCE_PASS glance
openstack role add --project service --user glance admin
openstack service create --name glance \
  --description "OpenStack Image" image
openstack endpoint create --region RegionOne \
  image public http://controller:9292
openstack endpoint create --region RegionOne \
  image internal http://controller:9292
openstack endpoint create --region RegionOne \
  image admin http://controller:9292


apt install glance -y

# configrue /etc/glance/glance-api.conf 
/bin/sh ./glance/controller-glance-api-conf.sh

# configrue the /etc/glance/glance-registry.conf
/bin/sh ./glance/controller-glance-registry-conf.sh

/bin/sh -c "glance-manage db_sync" glance

service glance-registry restart
service glance-api restart

. ./admin-openrc


# download and register cirros image 
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img

openstack image create "cirros" \
  --file cirros-0.4.0-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --public


# install nova ------------------------------------------

# configure nova db
mysql<<EOF
CREATE DATABASE nova_api;
CREATE DATABASE nova;
CREATE DATABASE nova_cell0;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
  IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
  IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
  IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
  IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' \
  IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' \
  IDENTIFIED BY '$NOVA_DBPASS';
EOF

. ./admin-openrc

openstack user create --domain default --password $NOVA_PASS nova
openstack role add --project service --user nova admin
openstack service create --name nova \
  --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1

openstack user create --domain default --password $PLACEMENT_PASS placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778


apt install -y nova-api nova-conductor nova-consoleauth \
  nova-novncproxy nova-scheduler nova-placement-api

# configure /etc/nova/nova.conf 
/bin/sh ./nova/controller-nova-conf.sh

/bin/sh -c "nova-manage api_db sync" nova
/bin/sh -c "nova-manage cell_v2 map_cell0" nova
/bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
/bin/sh -c "nova-manage db sync" nova

service nova-api restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

# after nova-compute installation
. ./admin-openrc

openstack compute service list --service nova-compute

/bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

# install verify
# . admin-openrc
# openstack compute service list
# openstack catalog list
# openstack image list


# install neutron ------------------------------------------

# configure neutron db
mysql -u root -p$DB_ROOT_PASS<<EOF
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY '$NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY '$NEUTRON_DBPASS';
EOF

. ./admin-openrc

openstack user create --domain default --password $NEUTRON_PASS neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron \
  --description "OpenStack Networking" network

openstack endpoint create --region RegionOne \
  network public http://controller:9696

openstack endpoint create --region RegionOne \
  network internal http://controller:9696

openstack endpoint create --region RegionOne \
  network admin http://controller:9696


apt install -y neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent


# configure the /etc/neutron/neutron.conf 
/bin/sh ./neutron/controller-neutron-conf.sh

# configure /etc/neutron/plugins/ml2/ml2_conf.ini 
/bin/sh ./neutron/controller-neutron-ml2_conf-ini.sh

# configure /etc/neutron/plugins/ml2/linuxbridge_agent.ini 
/bin/sh ./neutron/controller-neutron-linuxbridge_agent-ini.sh

# enable networking bridge support
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
sysctl -p

# configure /etc/neutron/l3_agent.ini 
/bin/sh ./neutron/controller-neutron-l3_agent-ini.sh

# configure /etc/neutron/dhcp_agent.ini
/bin/sh ./neutron/controller-neutron-dhcp_agent-ini.sh

# configure /etc/neutron/metadata_agent.ini 
/bin/sh ./neutron/controller-neutron-metadata_agent-ini.sh

/bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service nova-api restart

service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

service neutron-l3-agent restart