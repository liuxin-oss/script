#!/bin/bash
echo "#################Start####################"

echo "安装openvpn软件"
yum -y install epel-release &>>/dev/null
yum -y install openvpn easy-rsa iptables-services &>>/dev/null


echo "创建证书环境目录"
cp -r /usr/share/easy-rsa/ /etc/openvpn/easy-rsa 

echo "初始化"
cd /etc/openvpn/easy-rsa/3/
echo "yes" | ./easyrsa init-pki	&>>/dev/null

echo "创建根证书"
echo "yes" | ./easyrsa build-ca nopass &>>/dev/null

echo "创建server端证书和私钥文件"
echo "yes" | ./easyrsa gen-req server nopass  &>>/dev/null

echo "给server证书签名"
echo "yes" | ./easyrsa sign server server &>>/dev/null

echo "创建Diffie-Hellman文件"
./easyrsa gen-dh &>>/dev/null

echo "创建client端证书和私钥文件"
echo "yes" | ./easyrsa gen-req liuxin nopass &>>/dev/null

echo "给client端证书签名"
echo "yes" | ./easyrsa sign client liuxin &>>/dev/null

echo "拷贝服务端的4个文件"
cp /etc/openvpn/easy-rsa/3/pki/ca.crt /etc/openvpn/
cp /etc/openvpn/easy-rsa/3/pki/issued/server.crt /etc/openvpn/
cp /etc/openvpn/easy-rsa/3/pki/private/server.key /etc/openvpn/
cp /etc/openvpn/easy-rsa/3/pki/dh.pem /etc/openvpn/

echo "拷贝客户端的3个文件"
cp /etc/openvpn/easy-rsa/3/pki/private/liuxin.key /etc/openvpn/client/
cp /etc/openvpn/easy-rsa/3/pki/issued/liuxin.crt /etc/openvpn/client/
cd /etc/openvpn/
cp ca.crt client/

echo "修改配置文件"
mkdir /var/log/openvpn &>>/dev/null
cat > server.conf <<EOF
local 0.0.0.0     #监听地址
port 1194     #监听端口
proto udp    #监听协议
dev tun     #采用路由隧道模式
ca /etc/openvpn/ca.crt      #ca证书路径
cert /etc/openvpn/server.crt       #服务器证书
key /etc/openvpn/server.key  # This file should be kept secret 服务器秘钥
dh /etc/openvpn/dh.pem     #密钥交换协议文件
server 10.8.0.0 255.255.255.0     #给客户端分配地址池，注意：不能和VPN服务器内网网段有相同
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"      #给网关
push "dhcp-option DNS 8.8.8.8"        #dhcp分配dns
client-to-client       #客户端之间互相通信
keepalive 10 120       #存活时间，10秒ping一次,120 如未收到响应则视为断线
comp-lzo      #传输数据压缩
max-clients 100     #最多允许 100 客户端连接
user openvpn       #用户
group openvpn      #用户组
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
log         /var/log/openvpn/openvpn.log
verb 3
duplicate-cn
explicit-exit-notify 1 #UDP开启,TCP不用
EOF


cd
chown -R openvpn.openvpn /var/log/openvpn
chown -R openvpn.openvpn /etc/openvpn/*

echo "把openvpn定义成一个服务"
cat > /lib/systemd/system/openvpn@.service <<EOF
[Unit]
 
Description=OpenVPN Robust And Highly Flexible Tunneling Application On %I
 
After=network.target
[Service]
 
Type=notify
 
PrivateTmp=true
 
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf
[Install]
 
WantedBy=multi-user.target
EOF

echo "启动openvpn"
systemctl enable openvpn@server
systemctl start openvpn@server


echo "配置系统转发"
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sysctl -p &>>/dev/null


echo "关闭防火墙"
systemctl stop firewalld --now &>>/dev/null

echo "iptables设置"
systemctl restart openvpn@server
iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE


echo "生成客户端配置文件"
cd /etc/openvpn/client/
cat > liuxin.ovpn <<EOF
client
dev tun
proto udp
remote 118.89.59.191 1194    
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert liuxin.crt 
key liuxin.key  
comp-lzo no
verb 3
remote-cert-tls server
allow-compression no
EOF


echo "#################PASS####################"
