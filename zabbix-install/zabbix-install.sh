#!/bin/bash
source zabbix-var.sh
source zabbix-fuc.sh

function main()
{
	basic
	zabbix_template
	zabbix_db
	zabbix_server
	zabbix_web
}
main

