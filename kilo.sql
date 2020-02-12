CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'zeon9989';
CREATE DATABASE glance;
GRANT ALL ON glance.* TO 'glance'@'%' IDENTIFIED BY 'zeon9989';
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'zeon9989';
CREATE DATABASE neutron;
GRANT ALL ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'zeon9989';
quit;