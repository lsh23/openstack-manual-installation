cat > /etc/glance/glance-api.conf << EOF

[DEFAULT]

[database]
connection = mysql+pymysql://glance:$GLANCE_DBPASS@controller/glance
backend = sqlalchemy


[glance_store]

stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/


[image_format]

disk_formats = ami,ari,aki,vhd,vhdx,vmdk,raw,qcow2,vdi,iso,ploop.root-tar


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