cat > /etc/glance/glance-registry.conf << EOF
[DEFAULT]

[database]

connection = mysql+pymysql://glance:$GLANCE_DBPASS@controller/glance
backend = sqlalchemy


[keystone_authtoken]

auth_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = $GLANCE_PASS


[paste_deploy]

flavor = keystone

EOF