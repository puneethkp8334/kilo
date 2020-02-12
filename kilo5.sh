#!/bin/bash
IP="192.168.10.100"
DBPASS="zeon9989"
echo "$DBPASS"

ovs-vsctl add-port br-eth1 eth1
ovs-vsctl add-port br-ex eth2

cat <<EOF > /etc/network/interfaces
auto eth1
iface eth1 inet manual
ovs_bridge br-eth1
ovs_type OVSPort
adress 0.0.0.0

auto br-eth1
iface br-eth1 inet static
address 10.0.0.1
netmask 255.255.255.0
# dns-* options are implemented by the resolvconf package, if installed
dns-nameservers 8.8.8.8
#dns-search tplab.tippingpoint.com
ovs_type OVSBridge
ovs_ports br-eth1
bridgr_porte eth1
bridge_stp off
bridge_fd 0
bridge_maxwait 0
auto eth2
iface eth2 inet manual
ovs_bridge br-ex
ovs_type OVSPort
adress 0.0.0.0

auto br-ex
iface br-ex inet static
address 192.168.10.100
netmask 255.255.255.0
gateway 192.168.10.1
# dns-* options are implemented by the resolvconf package, if installed
#dns-search tplab.tippingpoint.com
ovs_type OVSBridge
ovs_ports br-ex
bridgr_porte ex
bridge_stp off
bridge_fd 0
bridge_maxwait 0

EOF

neutron net-create N1
neutron subnet-create --name subnetone N1 10.0.0.0/24 --dns-nameserver 192.168.10.1 
neutron net-create Extnet --provider:network_type flat --provider:physical_network External --router:external  --shared 

neutron subnet-create --name Externalsubnet --gateway 192.168.10.1 Extnet 192.160.10..0/24 --enable_dhcp False --allocation-pool start=192.168.10.50,end=192.168.10.99 --gateway 192.168.10.1
neutron router-create EXTRouter
neutron router-interface-add EXTRouter subnetone
ovs-vsctl list-ifaces br-int
neutron router-gateway-set EXTRouter Extnet
ovs-vsctl list-ifaces br-ex
neutron router-port-list Extrouter
ip netns
#"select a  qrouter id and replace the exact id and execute the beloww commends "
#########################*****Importent***######################################
#ip netns exec qrouter-a8b94496-87eb-4ecc-add3-7e4236780d46 ip addr show       #
#ip netns exec qrouter-a8b94496-87eb-4ecc-add3-7e4236780d46 ip route           #
#ip netns exec qrouter-a8b94496-87eb-4ecc-add3-7e4236780d46 iptables -t nat -L #
################################################################################