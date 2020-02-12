#!/bin/bash
IP="192.168.10.100"
DBPASS="zeon9989"
echo "the password and ip is ip=$IP password=$DBPASS"
#cat >/etc/apt/apt.conf.d/02proxy <<EOF
#Acquire::http{ proxy "http://192.168.10.115:3142"; };
#EOF

 find /home/manage/kilo/ -type f -exec sed -i -e 's/192.168.10.100/$IP/g' {} \;
#sed 's/192.168.10.100/$IP/g' -i /home/manage/kilo/*    || { echo " ip address failed"; exit 1; }
#Set update
apt-get update || { echo "update FAILED"; exit 1;}
apt-get install openssh* -y|| { echo "OPENSSH SERVER INSTALLATION failed"; exit 1;}

apt-get install -y rabbitmq-server &&
rabbitmqctl change_password guest rabbit &&
apt-get install -y mysql-server python-mysqldb || { echo "mysql server install  failed"; exit 1;} &&
sed 's/127.0.0.1/0.0.0.0/' -i /etc/mysql/my.cnf || { echo " mysql bind address failed"; exit 1; }
sed -i '/skip-external-locking/a innodb_file_per_table' /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i '/skip-external-locking/a collation-server = utf8_general_ci' /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i '/skip-external-locking/a init-connect = "SET NAMES utf8"' /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i '/skip-external-locking/a character-set-server = utf8' /etc/mysql/mysql.conf.d/mysqld.cnf

mysql -u root -p$DBPASS -e "create database keystone; GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$DBPASS'; create database glance; GRANT ALL ON glance.* TO 'glance'@'%' IDENTIFIED BY '$DBPASS'; create database nova; GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$DBPASS'; CREATE DATABASE neutron;
GRANT ALL ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$DBPASS';"


cat <<EOF >> /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
EOF

apt-get install -y keystone &&
#sed 's/connection = mysql://keystone:zeon9989@192.168.10.100/keystone/LoginGraceTime 20/' -i /etc/ssh/sshd_config || { echo "CHANGE GRACE TIME failedt 1"; }
cat <<EOF >> /etc/keystone/keystone.conf
[DEFAULT]
log_dir = /var/log/keystone
[assignment]
[auth]
[cache]
[catalog]
[credential]
[database]
connection = mysql://keystone:$DBPASS@$IP/keystone
[domain_config]
[endpoint_filter]
[endpoint_policy]
[eventlet_server]
[eventlet_server_ssl]
[federation]
[fernet_tokens]
[identity]
[identity_mapping][kvs][ldap]
[matchmaker_redis][matchmaker_ring][memcache][oauth1][os_inherit][oslo_messaging_amqp][oslo_messaging_qpid][oslo_messaging_rabbit][oslo_middleware]
[oslo_policy][paste_deploy]
[policy]
[resource][revoke][role][saml][signing][ssl][token][trust][extra_headers]
Distribution = Ubuntu
EOF

service keystone restart
keystone-manage db_sync

cat <<EOF > /home/manage/kilo.rc
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://$IP:35357/v2.0
EOF
source /home/manage/kilo.rc
keystone tenant-create --name=admin --description="Admin Tenant"
keystone tenant-create --name=service --description="Service Tenant"
keystone user-create --name=admin --pass=ADMIN --email=puneeth@agniinfo.com
keystone role-create --name=admin
keystone user-role-add --user=admin --tenant=admin --role=admin

keystone service-create --name=keystone --type=identity --description="Keystone Identity Service
keystone endpoint-create --service=keystone --publicurl=http://$IP:5000/v2.0 --internalurl=http://$IP:5000/v2.0 --adminurl=http://$IP:35357/v2.0
keystone token-get
keystone user-list