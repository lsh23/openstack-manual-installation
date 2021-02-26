cat > /etc/keystone/keystone.conf << EOF
[DEFAULT]
log_dir = /var/log/keystone

[database]
connection = mysql+pymysql://keystone:$KEYSTONE_DBPASS@controller/keystone


[token]
provider = fernet

EOF

