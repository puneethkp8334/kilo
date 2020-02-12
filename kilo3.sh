#!/bin/bash
IP="192.168.10.100"
DBPASS="zeon9989"
echo "$DBPASS"
apt-get install nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient nova-compute nova-console  -y|| { echo "NOVA INSTALLATION failed"; exit 1;}
keystone user-create --name=nova --pass=$DBPASS --email=puneeth@agniinfo.com
keystone user-role-add --user=nova --tenant=service --role=admin
keystone service-create --name=nova --type=compute --description="OpenStack Compute"
keystone endpoint-create --service=nova --publicurl=http://$IP:8774/v2/%\(tenant_id\)s --internalurl=http://$IP:8774/v2/%\(tenant_id\)s --adminurl=http://$IP:8774/v2/%\(tenant_id\)s
cat <<EOF > /etc/nova/nova.conf
rpc_backend = rabbit
auth_strategy = keystone
my_ip = $IP
vnc_enabled = True
vncserver_listen = $IP
vncserver_proxyclient_address = $IP
novncproxy_base_url = http://$IP:6080/vnc_auto.html

network_api_class = nova.network.neutronv2.api.API
security_group_api = neutron
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver

scheduler_default_filters=AllHostsFilter

[database]
connection = mysql://nova:$DBPASS@$IP/nova

[oslo_messaging_rabbit]
rabbit_host = 127.0.0.1
rabbit_password = rabbit

[keystone_authtoken]
auth_uri = http://$IP:5000
auth_url = http://$IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = nova
password = $DBPASS

[glance]
host = $IP

[oslo_concurrency]
lock_path = /var/lock/nova

[neutron]
service_metadata_proxy = True
metadata_proxy_shared_secret = openstack
url = http://$IP:9696
auth_strategy = keystone
admin_auth_url = http://$IP:35357/v2.0
admin_tenant_name = service
admin_username = neutron
admin_password = $DBPASS
EOF

nova-manage db sync &&
service nova-api restart ;service nova-cert restart; service nova-consoleauth restart &&
service nova-scheduler restart;service nova-conductor restart; service nova-novncproxy restart &&
service nova-compute restart; service nova-console restart &&

nova-manage service list