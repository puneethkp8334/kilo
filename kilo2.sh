#!/bin/bash
IP="192.168.10.100"
DBPASS="zeon9989"
echo "$DBPASS"
apt-get install -y glance &&
keystone user-create --name=glance --pass=$DBPASS --email=puneeth@agniinfo.com
keystone user-role-add --user=glance --tenant=service --role=admin
keystone service-create --name=glance --type=image --description="Glance Image Service"
keystone endpoint-create --service=glance --publicurl=http://$IP:9292 --internalurl=http://$IP:9292 --adminurl=http://$IP:9292


cat <<EOF > /etc/glance/glance-api.conf
[DEFAULT]
# Address to bind the API server
bind_host = 0.0.0.0
# Port the bind the API server to
bind_port = 9292
# sent to stdout as a fallback.
log_file = /var/log/glance/api.log
# Backlog requests when creating socket
backlog = 4096
# Address to find the registry server
registry_host = 0.0.0.0
# Port the registry server is listening on
registry_port = 9191
# Set to https for secure HTTP communication
registry_client_protocol = http

# the defaults)
rabbit_host = localhost
rabbit_port = 5672
rabbit_use_ssl = false
rabbit_userid = guest
rabbit_password = rabbit
rabbit_virtual_host = /
rabbit_notification_exchange = glance
rabbit_notification_topic = notifications
rabbit_durable_queues = False

# Configuration options if sending notifications via Qpid (these are
# the defaults)
qpid_notification_exchange = glance
qpid_notification_topic = notifications
qpid_hostname = localhost
qpid_port = 5672
qpid_username =
qpid_password =
qpid_sasl_mechanisms =
qpid_reconnect_timeout = 0
qpid_reconnect_limit = 0
qpid_reconnect_interval_min = 0
qpid_reconnect_interval_max = 0
qpid_reconnect_interval = 0
qpid_heartbeat = 5
# Set to 'ssl' to enable SSL
qpid_protocol = tcp
qpid_tcp_nodelay = True
# Turn on/off delayed delete
delayed_delete = False

# Delayed delete time in seconds
scrub_time = 43200
scrubber_datadir = /var/lib/glance/scrubber

# Base directory that the Image Cache uses
image_cache_dir = /var/lib/glance/image-cache/
[oslo_policy]
[database]
# The file name to use with SQLite (string value)
#sqlite_db = /var/lib/glance/glance.sqlite
connection = mysql://glance:$DBPASS@$IP/glance
# If True, SQLite uses synchronous mode (boolean value)
#sqlite_synchronous = True
[oslo_concurrency]
FAULT]/lock_path (string value)
#lock_path = /tmp
[keystone_authtoken]
identity_uri = http://$IP:35357
admin_tenant_name = service
admin_user = glance
admin_password = zeon9989
[paste_deploy]
# Name of the paste configuration file that defines the available pipelines
#config_file = glance-api-paste.ini
flavor = keystone
[store_type_location_strategy]
[profiler]
[task]
[taskflow_executor]
[glance_store]
default_store = file
# writes image data to
filesystem_store_datadir = /var/lib/glance/images/
# Valid versions are '2' for keystone and '1' for swauth and rackspace
swift_store_auth_version = 2
# For swauth, use something like '127.0.0.1:8080/v1.0/'
swift_store_auth_address = 127.0.0.1:5000/v2.0/
# is a user in that account
swift_store_user = jdoe:jdoe
# Auth key for the user authenticating against the
# Swift authentication service
swift_store_key = a86850deb2742ec3cb41518e26aa2d89
# Container within the account that the account should use
# for storing images in Swift
swift_store_container = glance
# Do we create the container if it does not exist?
swift_store_create_container_on_put = False
swift_store_large_object_size = 5120
swift_store_large_object_chunk_size = 200
# User to authenticate against the S3 authentication service
s3_store_access_key = <20-char AWS access key>
# Auth key for the user authenticating against the
# S3 authentication service
s3_store_secret_key = <40-char AWS secret key>
# your AWS access key if you use it in your bucket name below!
s3_store_bucket = <lowercased 20-char aws access key>glance
# Do we create the bucket if it does not exist?
s3_store_create_bucket_on_put = False
#s3_store_object_buffer_dir = /path/to/dir
# ============ Sheepdog Store Options =============================
sheepdog_store_address = localhost
sheepdog_store_port = 7000
sheepdog_store_chunk_size = 64
EOF

service glance-api restart
service glance-registry restart
glance-manage db_sync
glance image-create --name Cirros --is-public true --container-format bare --disk-format qcow2 --location https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img
glance image-list