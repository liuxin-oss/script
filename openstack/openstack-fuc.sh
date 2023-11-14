#以下是对controller节点定义的函数
function basic()
{
	echo "openstack-controller节点基础配置"
	#设置免密登陆
	sshpass -p 1 ssh-copy-id root@$controller &>>/dev/null
	echo "设置openstack-controller的免密登陆"
	sshpass -p 1 ssh-copy-id root@$compute1 &>>/dev/null
	echo "设置compute1的免密登陆"
	sshpass -p 1 ssh-copy-id root@$compute2 &>>/dev/null
	echo "设置compute2的免密登陆"
	sshpass -p 1 ssh-copy-id root@$network &>>/dev/null
	echo "设置compute2的免密登陆"
#设置软件仓库,我们是centos8上部署openstack，control节点和network节点需要删除原来的repo，compute的节点必须保留自带的repo
ssh root@$controller rm -rf /etc/yum.repos.d/* &>>/dev/null
echo "清空controller的软件仓库"
ssh root@$network rm -rf /etc/yum.repos.d/* &>>/dev/null
echo "清空network的软件仓库"

ssh root@$controller 'hostnamectl set-hostname controller'
ssh root@$compute1 'hostnamectl set-hostname compute1'
ssh root@$compute2 'hostnamectl set-hostname compute2'
ssh root@$network 'hostnamectl set-hostname network'
cat > ./files/hosts <<EOF
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
::1 localhost localhost.localdomain localhost6 localhost6.localdomain6
$controller controller
EOF

cat > ./files/openstack.repo <<EOF
[baseos]
name=baseos
baseurl=https://mirrors.tencent.com/centos-vault/8.2.2004/BaseOS/x86_64/os/
enabled=1
gpgcheck=0
[appstream]
name=appstream
baseurl=https://mirrors.tencent.com/centos-vault/8.2.2004/AppStream/x86_64/os/
enabled=1
gpgcheck=0
[powertools]
name=powertools
baseurl=https://mirrors.tencent.com/centos-vault/8.2.2004/PowerTools/x86_64/os/
enabled=1
gpgcheck=0
[cloud-u]
name=cloud-u
baseurl=https://mirrors.tencent.com/centos-vault/8.2.2004/cloud/x86_64/openstack-ussuri/
enabled=1
gpgcheck=0
[extras]
name=extras
baseurl=https://mirrors.tencent.com/centos-vault/8.2.2004/extras/x86_64/os/
enabled=1
gpgcheck=0
[nfv]
name=nfv
baseurl=https://mirrors.tencent.com/centos-vault/8.2.2004/extras/x86_64/os/
enabled=1
gpgcheck=0


[epel]
name=epel
baseurl=https://mirrors.tencent.com/epel/8/Everything/x86_64/
gpgcheck=0
enabled=1
[rabbitmq]
name=rabbitmq
baseurl=https://mirrors.tencent.com/centos-vault/8.2.2004/messaging/x86_64/rabbitmq-38/
enabled=1
gpgcheck=0

[advanced-virtualization]
name=advanced-virtualization
baseurl=https://mirrors.cloud.tencent.com/centos-vault/8.2.2004/virt/x86_64/advanced-virtualization/
enabled=1
gpgcheck=0
EOF
echo "生成软件仓库文件"

echo "拷贝hosts文件"
scp ./files/hosts root@$controller:/etc/hosts &>>/dev/null
scp ./files/hosts root@$compute1:/etc/hosts &>>/dev/null
scp ./files/hosts root@$compute2:/etc/hosts &>>/dev/null
scp ./files/hosts root@$network:/etc/hosts &>>/dev/null

echo "拷贝openstack.reop文件"
scp ./files/openstack.repo root@$controller:/etc/yum.repos.d/openstack.repo &>>/dev/null
scp ./files/openstack.repo root@$compute1:/etc/yum.repos.d/openstack.repo &>>/dev/null
scp ./files/openstack.repo root@$compute2:/etc/yum.repos.d/openstack.repo &>>/dev/null
scp ./files/openstack.repo root@$network:/etc/yum.repos.d/openstack.repo &>>/dev/null

#关闭防火墙和selinux
echo "关闭controller的防火墙和selinux"
ssh root@$controller "sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config && setenforce 0" &>>/dev/null
ssh root@$controller systemctl disable firewalld --now &>>/dev/null

echo "关闭compute1的防火墙和selinux"
ssh root@$compute1 "sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config && setenforce 0" &>>/dev/null
ssh root@$compute1 systemctl disable firewalld --now &>>/dev/null

echo "关闭compute2的防火墙和selinux"
ssh root@$compute2 "sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config && setenforce 0" &>>/dev/null
ssh root@$compute2 systemctl disable firewalld --now &>>/dev/null

echo "关闭network的防火墙和selinux"
ssh root@$network "sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config && setenforce 0" &>>/dev/null
ssh root@$network systemctl disable firewalld --now &>>/dev/null


}


function controller-ntp-server()
{
echo "安装chrony"
ssh root@$controller "yum install chrony -y" &>>/dev/null
echo "修改chrony配置文件"
ssh root@$controller "sed -i 's/^#allow.*/allow 10.163.4.0\/24/' /etc/chrony.conf"  &>>/dev/null
echo "重启chrony"
ssh root@$controller "systemctl restart  chronyd " &>>/dev/null
ssh root@$controller "systemctl enable  chronyd "  &>>/dev/null

}


function controller-openstackclient()
{
echo "controller节点安装python3-openstackclient"
ssh root@$controller "yum install python3-openstackclient python3 -y" &>>/dev/null
echo "controller节点安装openstack-selinux" 
ssh root@$controller "yum install openstack-selinux -y" &>>/dev/null


}


function controller-mariadb()
{
echo "controller节点安装mariadb"
ssh root@$controller "yum install mariadb mariadb-server python2-PyMySQL -y" &>>/dev/null
echo "生成mariadb配置文件"
cat > ./files/openstack.cnf <<EOF
[mysqld]
bind-address = $controller
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

echo "拷贝mairadb配置文件"
scp ./files/openstack.cnf root@$controller:/etc/my.cnf.d/openstack.cnf  &>>/dev/null
echo "启动数据库服务"
ssh root@$controller "systemctl restart mariadb.service" 
ssh root@$controller "systemctl enable mariadb.service" &>>/dev/null
}


function controller-rabbitmq()
{
echo "controller安装rabbitmq"
ssh root@$controller "yum install rabbitmq-server -y" &>>/dev/null

echo "启动rabbitmq服务"
ssh root@$controller "systemctl restart rabbitmq-server.service"  &>>/dev/null
ssh root@$controller "systemctl enable rabbitmq-server.service"  &>>/dev/null

echo "添加openstack用户并设置所有权限"
ssh root@$controller "rabbitmqctl add_user openstack RABBIT_PASS" &>>/dev/null
ssh root@$controller "rabbitmqctl set_permissions openstack '.*' '.*' '.*'" &>>/dev/null


}


function controller-memcache()
{
echo "controller安装memcache"
ssh root@$controller "yum install memcached python3-memcached  -y" &>>/dev/null

echo "修改配置文件/etc/sysconfig/memcached"
ssh root@$controller "sed -i 's/^OPTIONS.*/OPTIONS="-l controller"/' /etc/sysconfig/memcached" &>>/dev/null

echo "启动memcache服务"
ssh root@$controller "systemctl restart memcached.service" &>>/dev/null
ssh root@$controller "systemctl enable memcached.service" &>>/dev/null


}


function controller-etcd()
{
echo "controller安装etcd"
ssh root@$controller "yum install etcd -y" &>>/dev/null

echo "生成etcd.conf"
cat > ./files/etcd.conf <<EOF
Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://$controller:2380"
ETCD_LISTEN_CLIENT_URLS="http://$controller:2379"
ETCD_NAME="controller"                  
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$controller:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://$controller:2379"
ETCD_INITIAL_CLUSTER="controller=http://$controller:2380"     
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

echo "拷贝/etc/etcd/etcd.conf文件"
scp ./files/etcd.conf root@$controller:/etc/etcd/etcd.conf  &>>/dev/null

echo "启动etcd服务"
ssh root@$controller "systemctl restart etcd" &>>/dev/null
ssh root@$controller "systemctl enable etcd" &>>/dev/null
}


function keystone()
{
echo "创建keystone数据库"
ssh root@$controller "mysql -e \"CREATE DATABASE keystone;\"" &>>/dev/null
echo "设置keystone用户对数据的权限"
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"flush privileges;\"" &>>/dev/null


echo "安装keystone"
ssh root@$controller "yum install openstack-keystone httpd python3-mod_wsgi -y" &>>/dev/null

echo "生成keystone.conf"
cat > ./files/keystone.conf <<EOF
[DEFAULT]
[application_credential]
[assignment]
[auth]
[cache]
[catalog]
[cors]
[credential]
[database]
connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone
[domain_config]
[endpoint_filter]
[endpoint_policy]
[eventlet_server]
[federation]
[fernet_receipts]
[fernet_tokens]
[healthcheck]
[identity]
[identity_mapping]
[jwt_tokens]
[ldap]
[memcache]
[oauth1]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[policy]
[profiler]
[receipt]
[resource]
[revoke]
[role]
[saml]
[security_compliance]
[shadow_users]
[token]
provider = fernet
[tokenless_auth]
[totp]
[trust]
[unified_limit]
[wsgi]
EOF
echo "拷贝/etc/keystone/keystone.conf文件"
scp ./files/keystone.conf root@$controller:/etc/keystone/keystone.conf &>>/dev/null

echo "初始化keystone的数据库"
ssh root@$controller "su -s /bin/sh -c \"keystone-manage db_sync\" keystone" &>>/dev/null
echo "初始化keystone的fernet key"
ssh root@$controller "keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone" &>>/dev/null
ssh root@$controller "keystone-manage credential_setup --keystone-user keystone --keystone-group keystone" &>>/dev/null

echo "身份认证服务的初始化"
ssh root@$controller "keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
	--bootstrap-admin-url http://controller:5000/v3/ \
	--bootstrap-internal-url http://controller:5000/v3/ \
	--bootstrap-public-url http://controller:5000/v3/ \
	--bootstrap-region-id RegionOne" &>>/dev/null
echo "修改httpd的配置文件"
ssh root@$controller "sed -i 's/^#ServerName.*/ServerName controller/' /etc/httpd/conf/httpd.conf" &>>/dev/null
ssh root@$controller "ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/" &>>/dev/null

echo "重启web服务"
ssh root@$controller "systemctl restart httpd.service" &>>/dev/null
ssh root@$controller "systemctl enable httpd.service" &>>/dev/null


echo "设置凭据文件"
cat > ./files/adminrc <<EOF
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF

echo "拷贝凭据文件"
scp ./files/adminrc root@$controller:~/ &>>/dev/null

echo "加载凭据"
ssh root@$controller "source adminrc"

echo "生成创建project的脚本"
cat > ./files/create-project-service.sh <<EOF
#!/bin/bash
openstack project create --domain default --description "Service Project" service
EOF

echo "拷贝project脚本"
scp ./files/create-project-service.sh root@$controller:~/ &>>/dev/null
ssh root@$controller "chmod +x create-project-service.sh"
ssh root@$controller "source adminrc;/bin/bash create-project-service.sh" &>>/dev/null


}


function glance()
{
echo "glance db创建"
ssh root@$controller "mysql -e \"CREATE DATABASE glance;\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"flush privileges;\"" &>>/dev/null

echo "加载凭据"
ssh root@$controller "source adminrc"

echo "生成创建endpoint的脚本"
cat > ./files/create-image-endpoint.sh <<EOF
#!/bin/bash
openstack user create --domain default --password glance glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292   
EOF

echo "拷贝endpoint脚本"
scp ./files/create-image-endpoint.sh root@$controller:~/ &>>/dev/null 
ssh root@$controller "chmod +x create-image-endpoint.sh" &>>/dev/null
ssh root@$controller "source adminrc;/bin/bash create-image-endpoint.sh" &>>/dev/null


echo "安装glance"
ssh root@$controller "yum install openstack-glance -y" &>>/dev/null

echo "生成glance配置文件"
cat > ./files/glance-api.conf <<EOF
[DEFAULT]
[barbican]
[barbican_service_user]
[cinder]
[cors]
[database]
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
[file]
[glance.store.http.store]
[glance.store.rbd.store]
[glance.store.s3.store]
[glance.store.swift.store]
[glance.store.vmware_datastore.store]
[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/
[healthcheck]
[image_format]
[key_manager]
[keystone_authtoken]
www_authenticate_uri  = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = glance
[oslo_concurrency]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[oslo_reports]
[paste_deploy]
flavor = keystone
[profiler]
[store_type_location_strategy]
[task]
[taskflow_executor]
[vault]
[wsgi]
EOF

echo "拷贝/etc/glance/glance-api.conf"
scp ./files/glance-api.conf root@$controller:/etc/glance/glance-api.conf &>>/dev/null

echo "初始化glance的数据库"
ssh root@$controller "su -s /bin/sh -c \"glance-manage db_sync\" glance" &>>/dev/null

echo "启动glance服务"
ssh root@$controller "systemctl restart openstack-glance-api.service" &>>/dev/null
ssh root@$controller "systemctl enable openstack-glance-api.service" &>>/dev/null




}


function placement()
{
echo "配置placement数据库"
ssh root@$controller "mysql -e \"CREATE DATABASE placement;\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY 'PLACEMENT_DBPASS'\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'PLACEMENT_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"flush privileges;\"" &>>/dev/null


echo "生成创建endpoint的脚本"
cat > ./files/create-placement-endpoint.sh <<EOF
#!/bin/bash
openstack user create --domain default --password placement placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778

EOF

echo "拷贝endpoint脚本"
scp ./files/create-placement-endpoint.sh root@$controller:~/ &>>/dev/null
ssh root@$controller "chmod +x create-placement-endpoint.sh" &>>/dev/null
ssh root@$controller "source adminrc;/bin/bash create-placement-endpoint.sh" &>>/dev/null


echo "安装placement"
ssh root@$controller "yum install openstack-placement-api -y" &>>/dev/null

echo "生成placement配置文件"
cat > ./files/placement.conf <<EOF
[DEFAULT]
[api]
auth_strategy = keystone
[cors]
[keystone_authtoken]
auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = placement
[oslo_middleware]
[oslo_policy]
[placement]
[placement_database]
connection = mysql+pymysql://placement:PLACEMENT_DBPASS@controller/placement
[profiler]
EOF
echo "拷贝/etc/placement/placement.conf"
scp ./files/placement.conf root@$controller:/etc/placement/placement.conf &>>/dev/null

echo "placement的bug"
cat > ./files/00-placement-api.conf <<EOF
Listen 8778

<VirtualHost *:8778>
  WSGIProcessGroup placement-api
  WSGIApplicationGroup %{GLOBAL}
  WSGIPassAuthorization On
  WSGIDaemonProcess placement-api processes=3 threads=1 user=placement group=placement
  WSGIScriptAlias / /usr/bin/placement-api
  <IfVersion >= 2.4>
    ErrorLogFormat "%M"
  </IfVersion>
  ErrorLog /var/log/placement/placement-api.log
  #SSLEngine On
  #SSLCertificateFile ...
  #SSLCertificateKeyFile ...
</VirtualHost>

Alias /placement-api /usr/bin/placement-api
<Location /placement-api>
  SetHandler wsgi-script
  Options +ExecCGI
  WSGIProcessGroup placement-api
  WSGIApplicationGroup %{GLOBAL}
  WSGIPassAuthorization On
</Location>
<Directory /usr/bin>
    <IfVersion >= 2.4>
      Require all granted
    </IfVersion>
    <IfVersion < 2.4>
      Order allow.deny
      Allow from all
    </IfVersion>
</Directory>
EOF
scp ./files/00-placement-api.conf root@$controller:/etc/httpd/conf.d/00-placement-api.conf &>>/dev/null


echo "同步placement数据库"
ssh root@$controller "su -s /bin/sh -c \"placement-manage db sync\" placement" &>>/dev/null

echo "重启服务"
ssh root@$controller "systemctl restart httpd" &>>/dev/null


}


function controller-nova()
{
echo "创建nova的3个数据库"
ssh root@$controller "mysql -e \"CREATE DATABASE nova;\"" &>>/dev/null
ssh root@$controller "mysql -e \"CREATE DATABASE nova_api;\"" &>>/dev/null
ssh root@$controller "mysql -e \"CREATE DATABASE nova_cell0;\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';\"" &>>/dev/null

echo "生成创建endpoint的脚本"
cat > ./files/create-nova-endpoint.sh <<EOF
#!/bin/bash
openstack user create --domain default --password nova nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1
EOF

echo "拷贝endpoint脚本"
scp ./files/create-nova-endpoint.sh root@$controller:~/ &>>/dev/null
ssh root@$controller "chmod +x create-nova-endpoint.sh" &>>/dev/null
ssh root@$controller "source adminrc;/bin/bash create-nova-endpoint.sh" &>>/dev/null

echo "安装nova软件"
ssh root@$controller "yum install openstack-nova-api openstack-nova-conductor openstack-nova-novncproxy openstack-nova-scheduler -y" &>>/dev/null

echo "生成nova配置文件"
cat > ./files/nova.conf <<EOF
[DEFAULT]
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:RABBIT_PASS@controller:5672/
my_ip = $controller    #controler的ip地址
[api]
auth_strategy = keystone
[api_database]
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova_api
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
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova

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
# ...
server_listen = $controller
server_proxyclient_address = $controller
[workarounds]
[wsgi]
[xenserver]
[zvm]
EOF
echo "拷贝/etc/nova/nova.conf文件"
scp ./files/nova.conf root@$controller:/etc/nova/nova.conf &>/dev/null

echo "生成nova-api数据库"
ssh root@$controller "su -s /bin/sh -c \"nova-manage api_db sync\" nova" &>>/dev/null

echo "注册cell0的数据库"
ssh root@$controller "su -s /bin/sh -c \"nova-manage cell_v2 map_cell0\" nova" &>>/dev/null

echo "创建一个名字为cell1的子cell"
ssh root@$controller "su -s /bin/sh -c \"nova-manage cell_v2 create_cell --name=cell1 --verbose\" nova" &>>/dev/null

echo "同步nova数据库，忽略错误输出"
ssh root@$controller "su -s /bin/sh -c \"nova-manage db sync\" nova" &>>/dev/null

echo "启动控制节点的nova服务"
ssh root@$controller "systemctl restart \
	    openstack-nova-api.service \
            openstack-nova-scheduler.service \
            openstack-nova-conductor.service \
            openstack-nova-novncproxy.service "
ssh root@$controller "systemctl enable \
	    openstack-nova-api.service \
            openstack-nova-scheduler.service \
            openstack-nova-conductor.service \
            openstack-nova-novncproxy.service " &>>/dev/null

}


function controller-neutron()
{
echo "创建数据库"
ssh root@$controller "mysql -e \"CREATE DATABASE neutron;\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'NEUTRON_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'NEUTRON_DBPASS';\"" &>>/dev/null
ssh root@$controller "mysql -e \"flush privileges;\"" &>>/dev/null


echo "生成创建endpoint的脚本"
cat > ./files/create-neutron-endpoint.sh <<EOF
#!/bin/bash
openstack user create --domain default --password neutron neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://10.163.4.104:9696
openstack endpoint create --region RegionOne network internal http://10.163.4.104:9696
openstack endpoint create --region RegionOne network admin http://10.163.4.104:9696 
EOF

echo "拷贝endpoint脚本"
scp ./files/create-neutron-endpoint.sh root@$controller:~/ &>>/dev/null
ssh root@$controller "chmod +x create-neutron-endpoint.sh" &>>/dev/null
ssh root@$controller "source adminrc;/bin/bash create-neutron-endpoint.sh" &>>/dev/null

}




function controller-novafile-addneutron()
{
echo "删除[neutron]sector"
sed -i 's/\[neutron\]//g' ./files/nova.conf

echo "nova.conf文件追加neutron的部分"
cat >> ./files/nova.conf <<EOF
[neutron]
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = neutron
service_metadata_proxy = true
metadata_proxy_shared_secret = METADATA_SECRET
EOF

echo "拷贝新的/etc/nova/nova.conf文件"
scp ./files/nova.conf root@$controller:/etc/nova/nova.conf &>/dev/null

echo "重启控制节点的nova服务"
ssh root@$controller "systemctl restart openstack-nova-api.service" &>/dev/null




}
