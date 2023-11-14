#!/bin/bash
./lan-live.sh | grep -i up | awk '{print $1}' > livehosts 


cat > openstack-hosts <<END
#!/bin/bash
END
n=0
x=0
for i in `cat livehosts | sort -n`
do
	x=`expr $x + 1`
	if [ "$n" == 0 ]
	then
		echo "controller=$i" >> openstack-hosts 
	else
		if [ "$x" -lt 4 ]		#由于知道livehosts里有4个ip地址
		then
			echo "compute$n=$i" >> openstack-hosts
		fi
		if [ "$x" == 4 ]		#那最后一个地址当网络节点
		then 
			echo "network=$i" >> openstack-hosts
		fi
	fi
	n=`expr $n + 1`
done
