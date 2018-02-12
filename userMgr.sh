#!/bin/bash
action=$1
user=$2
group=$3
ret=0
chattr -i /etc/passwd /etc/shadow /etc/group /etc/gshadow
if [ ${action} = "del" ];then
	userdel  -r ${user}
	ret=$?
elif [ ${action} = "add" ];then
	if [ -z ${group} ];then
		useradd -m -s /bin/bash ${user}
		ret=$?
	else
		useradd -m -g ${group} -s /bin/bash ${user}
		ret=$?
	fi	
	mkdir -p /home/${user}/.ssh
	cp /tmp/id_rsa_pub.${user} /home/${user}/.ssh/authorized_keys
	chown -R ${user}:${group} /home/${user}/.ssh
	chmod -R 700 /home/${user}/.ssh
fi
chattr +i /etc/passwd /etc/shadow /etc/group /etc/gshadow
if [ ${ret} = 0 ]; then
	echo $action $user "succeed"
else
	echo $action $user "failed"
fi
