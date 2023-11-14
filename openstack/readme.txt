前提条件，我是在第三方的机器eve上运行该脚本，且局域网内只有四台主机，第一台为controller，最后一台为network，其余都为compute



1.在eve需要配置好到四台主机的免密，且写进hosts文件
  controoler节点主机名为: controller
  compute节点主机名为: computex
  network节点主机名为: network
2.files文件夹中包含了一个镜像文件，写好的hosts文件，一个repo
3.安装的openstack版本为u版
4.只支持四台主机，不然要修改脚本
5.运行脚本之后会在files文件下出现很多配置文件，如果半路出错，请重置环境再次运行


#直接运行openstack-install.sh文件