#!/bin/bash
bash ./detect.sh
source openstack-fuc.sh
source openstack-compute-fuc.sh
source openstack-var.sh

function main()
{
	basic
	controller-ntp-server
	controller-openstackclient
	controller-mariadb
	controller-rabbitmq
	controller-memcache
	controller-etcd
	keystone
	glance
	placement
	controller-nova
	compute1_nova
	compute2_nova
	discovery_hosts
	controller-neutron
	network-neutron
	controller-novafile-addneutron
	compute1-neutron
	compute2-neutron
	compute1-novafile-addneutron
	compute2-novafile-addneutron
}
main
