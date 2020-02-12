#!/bin/bash
IP="192.168.10.100"
DBPASS="zeon9989"
echo "$DBPASS"
apt-get install  neutron-server neutron-plugin-openvswitch neutron-plugin-openvswitch-agent neutron-common neutron-dhcp-agent neutron-l3-agent neutron-metadata-agent openvswitch-switch -y|| { echo "NOVA INSTALLATION failed"; exit 1;}

keystone user-create --name=neutron --pass=$DBPASS --email=puneeth@agniinfo.com.com
keystone service-create --name=neutron --type=network --description="OpenStack Networking"
keystone user-role-add --user=neutron --tenant=service --role=admin
keystone endpoint-create --service=neutron --publicurl http://$IP:9696 --adminurl http://$IP:9696  --internalurl http://$IP:9696

sed 's/192.168.10.100/$IP/g' -i /home/manage/kilo/neutron.conf || { echo " ip address failed"; exit 1; }
sed 's/zeon9989/$DBPASS/g' -i /home/manage/kilo/neutron.conf || { echo " ip address failed"; exit 1; }
mv /etc/neutron/neutron.conf /etc/neutron/neutron_org.conf
cp /home/manage/kilo/neutron.conf  /etc/neutron/neutron.conf .
mv /etc/neutron/plugins/ml2/ml2_conf.ini  /etc/neutron/plugins/ml2/ml2_conf_org.ini
cp /home/manage/kilo/ml2_conf.ini  /etc/neutron/plugins/ml2/ml2_conf.ini

ovs-vsctl add-br br-int
ovs-vsctl add-br br-eth1
ovs-vsctl add-br br-ex
sed 's/192.168.10.100/$IP/g' -i /home/manage/kilo/metadata_agent.ini  || { echo " ip address failed"; exit 1; }
sed 's/zeon9989/$DBPASS/g' -i /home/manage/kilo/metadata_agent.ini    || { echo " ip address failed"; exit 1; }

cat <<EOF >> /etc/neutron/dhcp_agent.ini
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
use_namespaces = True
EOF

cat <<EOF >> /etc/neutron/l3_agent.ini
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True
EOF

neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade kilo
service neutron-server restart; service neutron-plugin-openvswitch-agent restart;service neutron-metadata-agent restart; service neutron-dhcp-agent restart; service neutron-l3-agent restart
neutron agent-list
apt-get install  openstack-dashboard -y|| { echo "NOVA INSTALLATION failed"; exit 1;}
echo "click here http://$IP/horizon"
echo "to open username admin password=ADMIN"