function basic()
{
	#line zabbix节点基础配置
	#设置免密登陆
	sshpass -p 1 ssh-copy-id root@$server_ip &>>/dev/null
	echo "设置zabbix-server的免密登陆"
	sshpass -p 1 ssh-copy-id root@$db_ip &>>/dev/null
	echo "设置zabbix-db的免密登陆"
	sshpass -p 1 ssh-copy-id root@$web_ip &>>/dev/null
	echo "设置zabbix-web的免密登陆"
#设置软件仓库,我们是centos8上部署zabbix，所以我们只使用yum的仓库配置
ssh root@$server_ip rm -rf /etc/yum.repos.d/* &>>/dev/null
echo "清空zabbix-server的软件仓库"
ssh root@$db_ip rm -rf /etc/yum.repos.d/* &>>/dev/null
echo "清空zabbix-db的软件仓库"
ssh root@$web_ip rm -rf /etc/yum.repos.d/* &>>/dev/null
echo "清空zabbix-web的软件仓库"
ssh root@$server_ip 'hostnamectl set-hostname server'
ssh root@$db_ip 'hostnamectl set-hostname db'
ssh root@$web_ip 'hostnamectl set-hostname web'


cat > .repo.repo << END
[appstream]
name=appstream
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/8-stream/AppStream/x86_64/os/
enabled=1
gpgcheck=0
[baseos]
name=baseos
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/8-stream/BaseOS/x86_64/os/
enabled=1
gpgcheck=0
[extras]
name=extras
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/8-stream/extras/x86_64/os/
enabled=1
gpgcheck=0
[epel]
name=epel
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/8/Everything/x86_64/
enabled=1
gpgcheck=0
[zabbix]
name=zabbix
baseurl=https://mirrors.tuna.tsinghua.edu.cn/zabbix/zabbix/5.0/rhel/8/x86_64/
enabled=1
gpgcheck=0
END
echo "生成软件仓库文件"

scp .repo.repo root@$server_ip:/etc/yum.repos.d/repo.repo &>>/dev/null
echo "设置zabbix-server"的软件仓库
scp .repo.repo root@$db_ip:/etc/yum.repos.d/repo.repo &>>/dev/null
echo "设置zabbix-db"的软件仓库
scp .repo.repo root@$web_ip:/etc/yum.repos.d/repo.repo &>>/dev/null
echo "设置zabbix-web"的软件仓库

#关闭防火墙和selinux
ssh root@$server_ip "sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config && setenforce 0" &>>/dev/null
echo "关闭zabbix-server的selinux"
ssh root@$server_ip systemctl disable firewalld --now &>>/dev/null
echo "关闭zabbix-server的防火墙"
ssh root@$db_ip "sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config && setenforce 0" &>>/dev/null
echo "关闭zabbix-db的selinux"
ssh root@$db_ip systemctl disable firewalld --now &>>/dev/null
echo "关闭zabbix-db的防火墙"
ssh root@$web_ip "sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config && setenforce 0" &>>/dev/null
echo "关闭zabbix-web的selinux"
ssh root@$web_ip systemctl disable firewalld --now &>>/dev/null
echo "关闭zabbix-web的防火墙"

}






function zabbix_db()
{
	#line zabbix-db部署
	ssh root@$db_ip yum -y install mariadb-server zabbix-server-mysql &>>/dev/null
	echo "zabbix-db软件包安装"

	ssh root@$db_ip systemctl enable mariadb --now &>>/dev/null
	echo "启动zabbix-db数据库"

	ssh root@$db_ip 'mysql -e "drop database zabbix;"' &>>/dev/null
	echo "清除旧的zabbix-db数据库"

	ssh root@$db_ip 'mysql -e "create database zabbix character set utf8 collate utf8_bin;"' &>>/dev/null
	echo "创建zabbix数据库"

	ssh root@$db_ip "mysql -e \"grant all privileges on zabbix.* to zabbix@'%' identified by 'zabbix';\"" &>>/dev/null
	echo "为zabbix用户设置对zabbix数据库的权限"

	ssh root@$db_ip 'mysql -e "flush privileges;"' &>>/dev/null
	echo "刷新数据库权限"

	ssh root@$db_ip 'zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -uzabbix -pzabbix zabbix' &>>/dev/null
	echo "zabbix-db的数据库导入"

}

function zabbix_server()
{
	sshserver="ssh root@$server_ip"
	#line zabbix-server部署
	$sshserver yum -y install zabbix-server-mysql &>>/dev/null
	echo "zabbix-server软件包安装"
	$sshserver "sed -i 's/^# DBHost.*/DBHost=$db_ip/' /etc/zabbix/zabbix_server.conf" &>>/dev/null
	echo "修改/etc/zabbix/zabbix_server.conf配置文件指定zabbix-db地址"
	$sshserver "sed -i 's/^# DBPassword.*/DBPassword=zabbix/' /etc/zabbix/zabbix_server.conf" &>>/dev/null
	echo "修改/etc/zabbix/zabbix_server.conf配置文件指定zabbix-db的数据库密码"
	$sshserver systemctl enable zabbix-server --now &>>/dev/null
	echo "启动zabbix-server服务"
}



function zabbix_web()
{
	#line zabbix-web部署
	sshserver="ssh root@$web_ip"
	$sshserver yum -y install zabbix-web-mysql zabbix-nginx-conf &>>/dev/null
	$sshserver yum -y install langpacks-zh_CN glibc-common &>>/dev/null
	echo "zabbix-web软件包安装"
	$sshserver "sed -i 's/^#.*listen.*/ listen 80;/' /etc/nginx/conf.d/zabbix.conf" &>>/dev/null
	echo "修改zabbix-web的nginx配置文件的监听端口"
	$sshserver "sed -i 's/^#.*server_name.*/ server_name $web_ip;/' /etc/nginx/conf.d/zabbix.conf" &>>/dev/null
	echo "修改zabbix-web的nginx配置文件的地址"
	$sshserver "sed -i 's/; php_value\[date\.timezone\] = Europe\/Riga/php_value\[date\.timezone\] = Asia\/Shanghai/' /etc/php-fpm.d/zabbix.conf" &>>/dev/null
	echo "修改zabbix-web的php配置文件指定时区为亚洲上海"
	scp .zabbix.conf.php root@$web_ip:/etc/zabbix/web/zabbix.conf.php &>>/dev/null
	echo "拷贝zabbix-web配置的模板文件"
	$sshserver systemctl enable nginx php-fpm --now &>>/dev/null
	echo "启动zabbix-web服务"
}


function zabbix_template()
{
	cat zabbix.conf.php.template | sed "s/db-ip/$db_ip/" | sed "s/server-ip/$server_ip/" > .zabbix.conf.php
}
