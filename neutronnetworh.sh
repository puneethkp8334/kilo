
root@sun:~# neutron net-create N1
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| id                        | beb5d2ca-46b0-45d7-a469-98d0575b7530 |
| name                      | N1                                   |
| provider:network_type     | vlan                                 |
| provider:physical_network | Intnet1                              |
| provider:segmentation_id  | 100                                  |
| router:external           | False                                |
| shared                    | False                                |
| status                    | ACTIVE                               |
| subnets                   |                                      |
| tenant_id                 | 8df4664c24bc40a4889fab4517e8e599     |
+---------------------------+--------------------------------------+

As can be seen no L3 information exists here. The L3 information like CIDR, DNS servers, DHCP addresses to be allocated are all part of the subnet definition. So prior to launching an Instance we create a subnet in the newly created network.

root@sun:~# neutron subnet-create --name subnetone N1 10.0.0.0/24 --dns-nameserver 192.168.10.1
+------------------+----------------------------------------------------+
| Field            | Value                                              |
+------------------+----------------------------------------------------+
| allocation_pools | {"start": "192.168.10.2", "end": "192.168.10.254"} |
| cidr             | 192.168.10.0/24                                    |
| dns_nameservers  | 10.8.16.3                                          |
| enable_dhcp      | True                                               |
| gateway_ip       | 192.168.10.1                                       |
| host_routes      |                                                    |
| id               | ccc80588-2b0d-459b-82e9-972ff4291b79               |
| ip_version       | 4                                                  |
| name             | subnetone                                          |
| network_id       | beb5d2ca-46b0-45d7-a469-98d0575b7530               |
| tenant_id        | 8df4664c24bc40a4889fab4517e8e599                   |
+------------------+----------------------------------------------------+

root@sun:~# neutron net-create Extnet --provider:network_type flat --provider:physical_network External --router:external True --shared True
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| id                        | 9c9436d4-2b7c-4787-8535-9835e6d9ac8e |
| name                      | Extnet                               |
| provider:network_type     | flat                                 |
| provider:physical_network | External                             |
| provider:segmentation_id  |                                      |
| router:external           | True                                 |
| shared                    | True                                 |
| status                    | ACTIVE                               |
| subnets                   | be9e9fbc-9140-4048-9636-eab2dd10d2e8 |
| tenant_id                 | 8df4664c24bc40a4889fab4517e8e599     |
+---------------------------+--------------------------------------+

The use of ‘–router:external’ is what makes a network ‘external’. The next step is to create a subnet on the external network. This subnet’s CIDR and gateway should match that of the datacenter/enterprise network corresponding to Extnet‘s physical network(bridged using br-ex). You do not need DHCP on this subnet as it would be taken care by your datacenter/enterprise network. Finally you also want to allocate only a specific set of IP’s on this network as the remaining might be used by other devices outside Openstack present in the datacenter.

#neutron subnet-create --name Externalsubnet --gateway 192.168.10.1 Extnet 192.168.10.0/24 --enable_dhcp False --allocation-pool start=192.168.10.0,end=192.168.10..49 --gateway 192.168.10.1
+------------------+------------------------------------------------+
| Field            | Value                                          |
+------------------+------------------------------------------------+
| allocation_pools | {"start": "10.8.127.10", "end": "10.8.127.49"} |
| cidr             | 10.8.127.0/24                                  |
| dns_nameservers  |                                                |
| enable_dhcp      | False                                          |
| gateway_ip       | 10.8.127.100                                   |
| host_routes      |                                                |
| id               | be9e9fbc-9140-4048-9636-eab2dd10d2e8           |
| ip_version       | 4                                              |
| name             | ExternalSubnet                                 |
| network_id       | 9c9436d4-2b7c-4787-8535-9835e6d9ac8e           |
| tenant_id        | 8df4664c24bc40a4889fab4517e8e599               |
+------------------+------------------------------------------------+

Note: A ‘port-create’ command on any internal network would eventually create that port on ‘br-int’, whereas the ports created on external network would be found on ‘br-ex’.
Routing

Routing is necessary if instances should have connectivity across subnets and also for accessing the external network. In openstack this functionality is achieved by creating a router using ‘neutron router-create’. I have created a single router ‘EXTRouter’ to connect my openstack networks to external networks.

root@sun:~# neutron router-create EXTRouter
+-----------------------+-----------------------------------------------------------------------------+
| Field                 | Value                                                                       |
+-----------------------+-----------------------------------------------------------------------------+
| admin_state_up        | True                                                                        |
| external_gateway_info |                                                                             |
| id                    | a8b94496-87eb-4ecc-add3-7e4236780d46                                        |
| name                  | EXTRouter                                                                   |
| routes                |                                                                             |
| status                | ACTIVE                                                                      |
| tenant_id             | 8df4664c24bc40a4889fab4517e8e599                                            |
+-----------------------+-----------------------------------------------------------------------------+

When the router is attached to ‘subnetone’ on ‘N1′(Internal Network), a new port is created and attaches ‘EXTRouter’ to ‘br-int’ which in my case happens to be ‘8d880345-e3a2-48dc-a45c-12873b228406‘.

root@sun:~# neutron router-interface-add EXTRouter subnetone
root@sun:~# ovs-vsctl list-ifaces br-int
int-br-eth1
int-br-ex
qr-8d880345-e3
tap6aeb772c-92

When the router is assigned an external gateway, a new port is created and attaches ‘EXTRouter’ to ‘br-ex’ which in my case happens to be ‘0525bfed-fe9e-4f4a-a0cc-67fb2020437f‘.

root@sun:~# neutron router-gateway-set EXTRouter Extnet
root@sun:~# ovs-vsctl list-ifaces br-ex
eth3
phy-br-ex
qg-0525bfed-fe
root@sun:~# neutron router-port-list Extrouter
+--------------------------------------+------+-------------------+-------------------------------------------------------------------------------------+
| id                                   | name | mac_address       | fixed_ips                                                                           |
+--------------------------------------+------+-------------------+-------------------------------------------------------------------------------------+
| 0525bfed-fe9e-4f4a-a0cc-67fb2020437f |      | fa:16:3e:06:f8:02 | {"subnet_id": "be9e9fbc-9140-4048-9636-eab2dd10d2e8", "ip_address": "10.8.127.10"}  |
| 8d880345-e3a2-48dc-a45c-12873b228406 |      | fa:16:3e:d5:1f:dd | {"subnet_id": "ccc80588-2b0d-459b-82e9-972ff4291b79", "ip_address": "192.168.10.1"} |
+--------------------------------------+------+-------------------+-------------------------------------------------------------------------------------+

To avoid IP clashes when two tenants try to use same network space, each router in Openstack is allocated a separate network namespace, which in my case happens to be ‘qrouter-a8b94496-87eb-4ecc-add3-7e4236780d46‘.

root@sun:~# ip netns
qdhcp-beb5d2ca-46b0-45d7-a469-98d0575b7530
qrouter-a8b94496-87eb-4ecc-add3-7e4236780d46

The router interfaces that are attached to br-int and br-ex actually exists inside the router’s namespace. To check execute ‘ip link show’ inside the namespace.

root@sun:~# ip netns exec qrouter-a8b94496-87eb-4ecc-add3-7e4236780d46 ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
34: qr-8d880345-e3: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default 
    link/ether fa:16:3e:d5:1f:dd brd ff:ff:ff:ff:ff:ff
    inet 192.168.10.1/24 brd 192.168.10.255 scope global qr-8d880345-e3
       valid_lft forever preferred_lft forever
    inet6 fe80::f816:3eff:fed5:1fdd/64 scope link 
       valid_lft forever preferred_lft forever
37: qg-0525bfed-fe: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default 
    link/ether fa:16:3e:06:f8:02 brd ff:ff:ff:ff:ff:ff
    inet 10.8.127.10/24 brd 10.8.127.255 scope global qg-0525bfed-fe
       valid_lft forever preferred_lft forever

The above namespace acts as the router itself and routes packets between the internal network(192.168.10.0/24) and the external network(10.8.127.0/24). My router’s interface on internal network is ‘192.168.10.1’ and that on the external network is ‘10.8.127.10’. All that is needed to start routing is to enable IP forwarding on the namespace and that can be done by setting ‘net.ipv4.ip_forward = 1′ in ‘/etc/sysctl.conf’. Thus the l3-agent uses the host’s networking stack to perform routing. You can execute ‘ip route’ command inside the namespace to check the same.

root@sun:~# ip netns exec qrouter-a8b94496-87eb-4ecc-add3-7e4236780d46 ip route
default via 10.8.127.100 dev qg-0525bfed-fe 
10.8.127.0/24 dev qg-0525bfed-fe  proto kernel  scope link  src 10.8.127.10 
192.168.10.0/24 dev qr-8d880345-e3  proto kernel  scope link  src 192.168.10.1 

My router above is configured with three routes. The default gateway ‘10.8.127.100‘ is none other than my external subnets gateway ip discussed earlier. The other two routes point to the external and internal networks respectively. Further reading is also encouraged.
Natting

The networks in Openstack are by default ‘Internal’ unless explicitly specified. The instances attached to these are not reachable from outside world. The instances themselves can reach internet, thanks to the ‘external network’. Each subnet in Openstack has a specific default gateway(which unless explicitly specified defaults to the first IP address in that subnet). In my case ‘subnetone’ had a default gateway of ‘192.168.10.1’, which happens to be EXTRouter’s interface on ‘N1′. Thus instances on ‘N1′ would use EXTRouter as their gateway. It now becomes the responsibility of EXTRouter to perform ‘natting and routing‘ prior to sending the packet out to the ‘external network‘(Remember to EXTRouter is attached both to internal and external networks). This functionality is achieved using ‘iptables‘.
Lets check what rules are present inside the routers’ namespace.

root@sun:~# ip netns exec qrouter-a8b94496-87eb-4ecc-add3-7e4236780d46 iptables -t nat -L
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
neutron-l3-agent-PREROUTING  all  --  anywhere             anywhere          

Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
neutron-l3-agent-OUTPUT  all  --  anywhere             anywhere            

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
neutron-l3-agent-POSTROUTING  all  --  anywhere             anywhere            
neutron-postrouting-bottom  all  --  anywhere             anywhere      

Chain neutron-l3-agent-OUTPUT (1 references)
target     prot opt source               destination         

Chain neutron-l3-agent-POSTROUTING (1 references)
target     prot opt source               destination         
ACCEPT     all  --  anywhere             anywhere             ! ctstate DNAT

Chain neutron-l3-agent-PREROUTING (1 references)
target     prot opt source               destination         
REDIRECT   tcp  --  anywhere             169.254.169.254      tcp dpt:http redir ports 9697

Chain neutron-l3-agent-float-snat (1 references)
target     prot opt source               destination         

Chain neutron-l3-agent-snat (1 references)
target     prot opt source               destination         
neutron-l3-agent-float-snat  all  --  anywhere             anywhere            
SNAT       all  --  192.168.10.0/24      anywhere             to:10.8.127.10

Chain neutron-postrouting-bottom (1 references)
target     prot opt source               destination         
neutron-l3-agent-snat  all  --  anywhere             anywhere    

Lets assume I try to reach ‘google’ from one of my instances. Packets from my instances would first hit the ‘PREROUTING’ -> ‘neutron-l3-agent-PREROUTING’. The ‘neutron-l3-agent-PREROUTING’ would redirect all http traffic to ‘169.254.169.254’ to port 9697 which is used by metadata agent. We would not delve in to its details.

Our packet would be unchanged after passing through ‘neutron-l3-agent-PREROUTING’ and so would go through the routing process which eventually would choose the default route ‘10.8.127.100’ which is our gateway of external network.

The packet then again starts traversing ‘POSTROUTING’ -> ‘neutron-postrouting-bottom‘ -> ‘neutron-l3-agent-snat‘, which is the chain highlighted above. The single rule in the chain would SNAT all packets to 10.8.127.10, which is EXTRouter’s interface on ‘Extnet'(external network).

The above rule would be useless if the instance receives reply from internet which can not be natted back to the correct instance and so exists ‘neutron-l3-agent-POSTROUTING‘
FloatingIP

As highlighted before, Instances on Openstack networks(Internal) are not reachable directly, not even from your local LAN. For that we first have to create a Floating IP on your external network. When created you have a IP address from ‘Externalsubnet'(subnet in external network).

root@sun:~# neutron floatingip-create Extnet
Created a new floatingip:
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| fixed_ip_address    |                                      |
| floating_ip_address | 10.8.127.11                          |
| floating_network_id | 9c9436d4-2b7c-4787-8535-9835e6d9ac8e |
| id                  | 7b4cee72-ffcd-4484-a5d8-371b23bb3cc3 |
| port_id             |                                      |
| router_id           |                                      |
| status              | ACTIVE                               |
| tenant_id           | 8df4664c24bc40a4889fab4517e8e599     |
+---------------------+--------------------------------------+

This floating IP can then be assigned to specific instances on any of your internal networks. To do so find out the ‘id’ of the port to which your instances is attached and then associate it to your newly created floating ip.

root@sun:~# neutron port-list | grep 192.168.10.26
| d74c703e-824a-41b1-b4b3-3cd4edfa22b3 |      | fa:16:3e:14:ff:6d | {"subnet_id": "ccc80588-2b0d-459b-82e9-972ff4291b79", "ip_address": "192.168.10.26"} |
root@sun:~# neutron floatingip-associate 7b4cee72-ffcd-4484-a5d8-371b23bb3cc3 d74c703e-824a-41b1-b4b3-3cd4edfa22b3
+---------------------+--------------------------------------+
| Field               | Value                                |
+---------------------+--------------------------------------+
| fixed_ip_address    | 192.168.10.26                        |
| floating_ip_address | 10.8.127.11                          |
| floating_network_id | 9c9436d4-2b7c-4787-8535-9835e6d9ac8e |
| id                  | 7b4cee72-ffcd-4484-a5d8-371b23bb3cc3 |
| port_id             | d74c703e-824a-41b1-b4b3-3cd4edfa22b3 |
| router_id           | a8b94496-87eb-4ecc-add3-7e4236780d46 |
| status              | ACTIVE                               |
| tenant_id           | 8df4664c24bc40a4889fab4517e8e599     |
+---------------------+--------------------------------------+

You could have done all that from dashboard. Now your instance whose private ip is ‘192.168.10.26’ would be reachable from your enterprise/data LAN on the IP ‘10.8.127.11’(an IP from external network). To do this the neutron-l3-agent again makes use of ‘iptables’. To check the same execute ‘iptables -t nat -L’ inside EXTRouter’s namespace. Also you can see that the routers interface on external network now has an additional ip address.

root@sun:~# ip netns exec qrouter-a8b94496-87eb-4ecc-add3-7e4236780d46 ip addr show qg-0525bfed-fe
37: qg-0525bfed-fe: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default 
    link/ether fa:16:3e:06:f8:02 brd ff:ff:ff:ff:ff:ff
    inet 10.8.127.10/24 brd 10.8.127.255 scope global qg-0525bfed-fe
       valid_lft forever preferred_lft forever
    inet 10.8.127.11/32 brd 10.8.127.11 scope global qg-0525bfed-fe
       valid_lft forever preferred_lft forever
root@sun:~# ip netns exec qrouter-a8b94496-87eb-4ecc-add3-7e4236780d46 iptables -t nat -L
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
neutron-l3-agent-PREROUTING  all  --  anywhere             anywhere            

Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
neutron-l3-agent-OUTPUT  all  --  anywhere             anywhere            

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
neutron-l3-agent-POSTROUTING  all  --  anywhere             anywhere            
neutron-postrouting-bottom  all  --  anywhere             anywhere            

Chain neutron-l3-agent-OUTPUT (1 references)
target     prot opt source               destination         
DNAT       all  --  anywhere             10.8.127.11          to:192.168.10.26

Chain neutron-l3-agent-POSTROUTING (1 references)
target     prot opt source               destination         
ACCEPT     all  --  anywhere             anywhere             ! ctstate DNAT

Chain neutron-l3-agent-PREROUTING (1 references)
target     prot opt source               destination         
REDIRECT   tcp  --  anywhere             169.254.169.254      tcp dpt:http redir ports 9697
DNAT       all  --  anywhere             10.8.127.11          to:192.168.10.26

Chain neutron-l3-agent-float-snat (1 references)
target     prot opt source               destination         
SNAT       all  --  192.168.10.26        anywhere             to:10.8.127.11

Chain neutron-l3-agent-snat (1 references)
target     prot opt source               destination         
neutron-l3-agent-float-snat  all  --  anywhere             anywhere            
SNAT       all  --  192.168.10.0/24      anywhere             to:10.8.127.10

Chain neutron-postrouting-bottom (1 references)
target     prot opt source               destination         
neutron-l3-agent-snat  all  --  anywhere             anywhere            

The highlighted rules translate 192.168.10.26 to 10.8.127.11 and vice versa. Post the translation the the packets would be either sent out qg-0525bfed-fe(to external network Extnet, outside openstack) or qr-8d880345-e3(internal network N1) based on the destination.
About these ads
Share this:

    2Click to share on Twitter (Opens in new window)2Share on Facebook (Opens in new window)Click to email this to a friend (Opens in new window)Click to print (Opens in new window)15Click to share on LinkedIn (Opens in new window)15Click to share on Reddit (Opens in new window)Click to share on Google+ (Opens in new window)Click to share on Tumblr (Opens in new window)Click to share on Pinterest (Opens in new window)Click to share on Pocket (Opens in new window)

Related

L2 connectivity in OpenStack using OpenvSwitch mechanism driverIn "Cloud"

Managing Openstack Internal/Data/External network in one interfaceIn "Cloud"

Vlan mode in OpenVswitch on OpenStack GrizzlyIn "Network Management"
15/09/2014Akilesh    
Post navigation
← Installing OpenStack-Glance (Juno) on FreeBSD 10.0
Bundling FreeBSD 10.x image for OpenStack →
4 thoughts on “L3 connectivity using neutron-l3-agent”

    flankw says:	
    17/03/2015 at 12:43 PM

    Can you confirm that the provider network(external) should be created by ‘admin’ user only?
    Reply	
        Akilesh says:	
        17/03/2015 at 12:55 PM

        Yes that is the default behaviour. By ‘admin’ user I mean whichever user has ‘admin role'(refer ‘keystone’ section of ‘).
        Reply	
    Sam says:	
    30/01/2015 at 3:10 AM

    > provider:physical_network External
    Did you define this “External” network as a bridge_mapping in your neutron/plugins/openvswitch/ovs_neutron_plugin.ini?
    What did you do with “external_network_bridge” setting in neutron/l3_agent.ini ?
    Reply	
        Akilesh says:	
        02/02/2015 at 6:36 PM

        Check the assumptions I have mentioned under Section ‘Using the same Interface for all Networks’. External is defined in bridge_mappings inside ml2_conf.ini. As for the ‘external_network_bridge’ in l3_agent.ini. It is not needed in ‘icehouse’. However there seems to be a bug in juno , possibly introduced because of ‘dvr’ development. Because of this ‘external_network_bridge’ should be set to ‘br-ex'(as per my assumptions). explicitly for l3 agent to work.
        Reply	

Leave a Reply
Search FOSSKB
Search

    Akilesh
    Johnson D
    naviensubramani
    eternaltyro

Blogs I Follow

    Steve McCurry's Blog
    My Blog
    NPTEL and Digi-MAT
    VIETSTACK
    Pinlabs Blog
    Kiran Murari
    Technology Consulting, Software Architecture Services around Cloud, Mobile and Internet of Things - Qruize Blog
    appdevexpress
    Just another complex system
    Coffee Breaks
    Railway Junction Blog
    vivek raghuwanshi
    SIA Photography
    ...in search of that perfect world.
    Chennai Focus - A Tabloid on Chennai
    Free and Open Source Software Knowledge Base
    Going GNU
    Qruize Technologies
    Good local Food
    John Vagabond's Physics and Chemistry Blog

September 2014 S 	M 	T 	W 	T 	F 	S
« Aug 	  	Oct »
 	1	2	3	4	5	6
7	8	9	10	11	12	13
14	15	16	17	18	19	20
21	22	23	24	25	26	27
28	29	30 	 
Blog Stats

    156,973 hits

Categories
Categories
Apache Apache 2.4 BSD Cloud Debian FAMP Fedora FreeBSD FreeBSD 10.0 Glance Havana IceHouse Image Management Instance Management Juno Keystone Linux Distribution Network Management Neutron Open source OpenSSH OpenStack OpenStack installation guide Open vSwitch Quantum sshd Ubuntu Uncategorized Virtualization Web Server
Top Posts & Pages

    OpenStack Kilo on Ubuntu 14.04 LTS and 15.04 - Single machine setup
    Managing Openstack Internal/Data/External network in one interface
    OpenStack Juno on Ubuntu 14.04 LTS and 14.10 - Single Machine Setup
    Installing Gnome on FreeBSD-10
    L2 connectivity in OpenStack using OpenvSwitch mechanism driver
    Installing Redmine on Ubuntu 14.04
    OpenStack IceHouse on Ubuntu 14.04 LTS and 12.04 LTS - Single machine setup
    Installing Mate desktop on FreeBSD-10
    L3 connectivity using neutron-l3-agent
    OpenStack Automated Install

Follow Blog via Email

Enter your email address to follow this blog and receive notifications of new posts by email.

Join 120 other followers

Tags
AD Apache Pig Installation authentication Building a customized kernel in FreeBSD10.0 Debian on OpenStack Desktop on FreeBSD DIY Django on FreeBSD FAMP server FreeBSD 9.1 Server in cloud FreeBSD Jail Guide FreeBSD on Raspberry Pi Games for Linux Gnome on FreeBSD GUI on FreeBSD GUI on FreeBSD 10 Hadoop Ecosystem Installation Hadoop Installation Guide Hadoop installation guide for Beginners Hadoop multi node setup Hbase Installation Hive Installation IAM Jails on FreeBSD10 LDAP Linux Containers LXC Managing FreeBSD jails Mate on FreeBSD 10 Nginx on FreeBSD OpenDaylight OpenLDAP Open Source Open Source Astronomy application Open Source Games OpenStack Beginner's Guide OpenStack Debian Instance OpenStack FreeBSD image OpenStack Grizzly Guide OpenStack Havana Guide OpenStack IceHouse guide OpenStack IceHouse on Ubuntu12.04 OpenStack IceHouse on Ubuntu14.04 OpenStack Juno OpenStack Juno Guide OpenStack Juno Installation Guide OpenStack Juno on Debian OpenStack Kilo OpenStack Kilo basic setup OpenStack kilo Single machine setup OpenStack on Debian guide OpenStack on FreeBSD OpenStack Quantum control flow Open vSwitch slapd Spark Installation Sqoop Installation SSH tunneling Stellarium Beginner's guide Stellarium doc Stellarium Guide Virtual Planetarium Wordpress on Ubuntu Yarn Installation
Top Clicks

    ubuntu-cloud-installer.re…
    fosskb.files.wordpress.co…
    zcentric.com/2014/07/07/o…
    fosskb.files.wordpress.co…
    blog.pinlabs.in/?p=2851
    blog.pinlabs.in/2014/11/2…
    fosskb.files.wordpress.co…
    fosskb.files.wordpress.co…
    github.com/Akilesh1597/sa…
    mirror.yandex.ru/freebsd/…

Blog at WordPress.com. ~ The Syntax Theme.
Follow
Follow “Free and Open Source Software Knowledge Base”

Get every new post delivered to your Inbox.

Join 120 other followers

Build a website with WordPress.com
