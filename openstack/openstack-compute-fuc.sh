#以下是对compute节点定义的函数

function compute1_nova()
{
echo "计算节点的软件仓库配置"
ssh root@$compute1 "yum install centos-release-openstack-ussuri -y" &>>/dev/null
ssh root@$compute1 "yum config-manager --set-enabled PowerTools" &>>/dev/null


echo "计算节点软件包安装"
ssh root@$compute1 "yum install openstack-nova-compute -y" &>>/dev/null

echo "生成compute1-nova.conf配置文件"
cat > ./files/compute1-nova.conf <<EOF
[DEFAULT]
my_ip = $compute1
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:RABBIT_PASS@controller
[api]
auth_strategy = keystone
[api_database]
[barbican]
[cache]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[cyborg]
[database]
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
api_servers = http://controller:9292
[guestfs]
[healthcheck]
[hyperv]
[image_cache]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
www_authenticate_uri = http://controller:5000/
auth_url = http://controller:5000/
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = nova
[libvirt]
virt_type = kvm
[metrics]
[mks]
[neutron]
[notifications]
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[pci]
[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = placement
[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
[service_user]
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = $compute1
novncproxy_base_url = http://controller:6080/vnc_auto.html
[workarounds]
[wsgi]
[xenserver]
[zvm]
EOF
echo "拷贝/etc/nova/nova.conf"
scp ./files/compute1-nova.conf root@compute1:/etc/nova/nova.conf &>>/dev/null

echo "启动服务"
ssh root@$compute1 "systemctl restart libvirtd.service openstack-nova-compute.service" &>>/dev/null
ssh root@$compute1 "systemctl enable libvirtd.service openstack-nova-compute.service" &>>/dev/null

}

function compute2_nova()
{
echo "计算节点的软件仓库配置"
ssh root@$compute2 "yum install centos-release-openstack-ussuri -y" &>>/dev/null
ssh root@$compute2 "yum config-manager --set-enabled PowerTools" &>>/dev/null


echo "计算节点软件包安装"
ssh root@$compute2 "yum install openstack-nova-compute -y" &>>/dev/null

echo "生成compute1-nova.conf配置文件"
cat > ./files/compute2-nova.conf <<EOF
[DEFAULT]
my_ip = $compute2
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:RABBIT_PASS@controller
[api]
auth_strategy = keystone
[api_database]
[barbican]
[cache]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[cyborg]
[database]
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
api_servers = http://controller:9292
[guestfs]
[healthcheck]
[hyperv]
[image_cache]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
www_authenticate_uri = http://controller:5000/
auth_url = http://controller:5000/
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = nova
[libvirt]
virt_type = kvm
[metrics]
[mks]
[neutron]
[notifications]
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[pci]
[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = placement
[powervm]
[privsep]
[profiler]
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
[service_user]
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address = $compute2
novncproxy_base_url = http://controller:6080/vnc_auto.html
[workarounds]
[wsgi]
[xenserver]
[zvm]
EOF
echo "拷贝/etc/nova/nova.conf"
scp ./files/compute2-nova.conf root@compute2:/etc/nova/nova.conf &>>/dev/null

echo "启动服务"
ssh root@$compute2 "systemctl restart libvirtd.service openstack-nova-compute.service" &>>/dev/null
ssh root@$compute2 "systemctl enable libvirtd.service openstack-nova-compute.service" &>>/dev/null




}

function discovery_hosts()
{
ssh root@$controller "su -s /bin/sh -c \"nova-manage cell_v2 discover_hosts --verbose\" nova" &>>/dev/null


}

function network-neutron()
{
echo "安装网络节点软件"
ssh root@$network "yum install openstack-neutron openstack-neutron-ml2 \
	         openstack-neutron-linuxbridge ebtables -y" &>>/dev/null
echo "生成neutron.conf文件"
cat > ./files/neutron.conf <<EOF
[DEFAULT]
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = true
transport_url = rabbit://openstack:RABBIT_PASS@controller
auth_strategy = keystone
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true

[cors]
[database]
connection = mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron
[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = neutron
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[privsep]
[ssl]
[nova]
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = nova
EOF

echo "拷贝/etc/neutron/neutron.conf文件"
scp ./files/neutron.conf root@$network:/etc/neutron/neutron.conf &>>/dev/null

echo "生成ml2_conf.ini文件"
cat > ./files/ml2_conf.ini <<EOF
[DEFAULT]
[ml2]
mechanism_drivers = linuxbridge,l2population
type_drivers = local,flat,vlan,vxlan
extension_drivers = port_security
tenant_network_types = local
[securitygroup]
enable_ipset = true
EOF

echo "拷贝/etc/neutron/plugins/ml2/ml2_conf.ini文件"
scp ./files/ml2_conf.ini root@$network:/etc/neutron/plugins/ml2/ml2_conf.ini &>>/dev/null

echo "生成L2 agent配置文件"
cat > ./files/linuxbridge_agent.ini <<EOF
[DEFAULT]
[securitygroup]
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
[vxlan]
enable_vxlan = false
EOF

echo "拷贝/etc/neutron/plugins/ml2/linuxbridge_agent.ini文件"
scp ./files/linuxbridge_agent.ini root@$network:/etc/neutron/plugins/ml2/linuxbridge_agent.ini &>>/dev/null

echo "加载br_netfilter模块"
cat > ./files/sysctl.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

echo "拷贝/etc/sysctl.conf文件"
scp ./files/sysctl.conf root@$network:/etc/sysctl.conf &>>/dev/null
ssh root@$network "modprobe br_netfilter"
ssh root@$network "sysctl -p"


echo "生成L3 agent的配置文件"
cat > ./files/l3_agent.ini <<EOF
[DEFAULT]
interface_driver = linuxbridge
EOF

echo "拷贝l3_agent.ini文件"
scp ./files/l3_agent.ini root@$network:/etc/neutron/l3_agent.ini  &>>/dev/null

echo "生成dhcp agent的配置文件"
cat > ./files/dhcp_agent.ini <<EOF
[DEFAULT]
interface_driver = linuxbridge
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
EOF

echo "拷贝/etc/neutron/dhcp_agent.ini文件"
scp ./files/dhcp_agent.ini root@$network:/etc/neutron/dhcp_agent.ini  &>>/dev/null

echo "生成metadata agent的配置文件"
cat > ./files/metadata_agent.ini <<EOF
[DEFAULT]
nova_metadata_host = controller
metadata_proxy_shared_secret = METADATA_SECRET
[cache]
EOF

echo "拷贝/etc/neutron/metadata_agent.ini文件"
scp ./files/metadata_agent.ini root@$network:/etc/neutron/metadata_agent.ini &>>/dev/null


echo "做配置文件软链接"
ssh root@$network "ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini" &>>/dev/null

echo "生成neutron的数据库"
ssh root@$network "su -s /bin/sh -c \"neutron-db-manage --config-file /etc/neutron/neutron.conf \
	  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head\" neutron" &>>/dev/null

echo "启动neutron的所有服务"
ssh root@$network "systemctl restart neutron-server.service \
	 neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
	  neutron-metadata-agent.service neutron-l3-agent.service" &>>/dev/null
ssh root@$network "systemctl enable neutron-server.service \
	 neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
	  neutron-metadata-agent.service neutron-l3-agent.service" &>>/dev/null


}



function compute1-neutron()
{

echo "安装软件包"
ssh root@$compute1 "yum install openstack-neutron-linuxbridge ebtables ipset -y" &>>/dev/null


echo "修改neutron的通用配置文件"
cat > ./files/compute1-neutron.conf <<EOF
[DEFAULT]
transport_url = rabbit://openstack:RABBIT_PASS@controller
auth_strategy = keystone
[cors]
[database]
[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = neutron
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp

[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[privsep]
[ssl]
EOF

echo "拷贝/etc/neutron/neutron.conf文件"
scp ./files/compute1-neutron.conf root@$compute1:/etc/neutron/neutron.conf &>>/dev/null


echo "拷贝/etc/neutron/plugins/ml2/linuxbridge_agent.ini文件"
scp ./files/linuxbridge_agent.ini root@$compute1:/etc/neutron/plugins/ml2/linuxbridge_agent.ini &>>/dev/null

echo "拷贝/etc/sysctl.conf文件"
scp ./files/sysctl.conf root@$compute1:/etc/sysctl.conf &>>/dev/null
ssh root@$compute1 "modprobe br_netfilter"
ssh root@$compute1 "sysctl -p"


ssh root@$compute1 "systemctl restart neutron-linuxbridge-agent.service "
ssh root@$compute1 "systemctl enable neutron-linuxbridge-agent.service "


}

function compute2-neutron()
{

echo "安装软件包"
ssh root@$compute2 "yum install openstack-neutron-linuxbridge ebtables ipset -y" &>>/dev/null


echo "修改neutron的通用配置文件"
cat > ./files/compute2-neutron.conf <<EOF
[DEFAULT]
transport_url = rabbit://openstack:RABBIT_PASS@controller
auth_strategy = keystone
[cors]
[database]
[keystone_authtoken]
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = neutron
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp

[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[privsep]
[ssl]
EOF

echo "拷贝/etc/neutron/neutron.conf文件"
scp ./files/compute2-neutron.conf root@$compute2:/etc/neutron/neutron.conf &>>/dev/null


echo "拷贝/etc/neutron/plugins/ml2/linuxbridge_agent.ini文件"
scp ./files/linuxbridge_agent.ini root@$compute2:/etc/neutron/plugins/ml2/linuxbridge_agent.ini &>>/dev/null

echo "拷贝/etc/sysctl.conf文件"
scp ./files/sysctl.conf root@$compute2:/etc/sysctl.conf &>>/dev/null
ssh root@$compute2 "modprobe br_netfilter"
ssh root@$compute2 "sysctl -p"


ssh root@$compute2 "systemctl restart neutron-linuxbridge-agent.service "
ssh root@$compute2 "systemctl enable neutron-linuxbridge-agent.service "


}





function compute1-novafile-addneutron()
{
echo "删除[neutron]sector"
sed -i 's/\[neutron\]//g' ./files/compute1-nova.conf

echo "nova.conf文件追加neutron的部分"
cat >> ./files/compute1-nova.conf <<EOF
[neutron]
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = neutron
EOF

echo "拷贝新的/etc/nova/nova.conf文件"
scp ./files/compute1-nova.conf root@$compute1:/etc/nova/nova.conf &>/dev/null

echo "重启nova服务"
ssh root@$compute1 "systemctl restart openstack-nova-compute.service" &>/dev/null



}




function compute2-novafile-addneutron()
{
echo "删除[neutron]sector"
sed -i 's/\[neutron\]//g' ./files/compute2-nova.conf

echo "nova.conf文件追加neutron的部分"
cat >> ./files/compute2-nova.conf <<EOF
[neutron]
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = neutron
EOF

echo "拷贝新的/etc/nova/nova.conf文件"
scp ./files/compute2-nova.conf root@$compute1:/etc/nova/nova.conf &>/dev/null

echo "重启nova服务"
ssh root@$compute2 "systemctl restart openstack-nova-compute.service" &>/dev/null



}
