#!/bin/bash
# Script to add a user to Linux system

if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p $pass $username

		DocumentRoot=/home/$username/www

		mkdir $DocumentRoot
		chmod 755 $DocumentRoot
		chown -R $username:$username $DocumentRoot

		cp -R /home/ec2-user/.ssh /home/$username
		chown -R $username:$username /home/$username/.ssh
		chmod 700 /home/$username/.ssh
		chmod 600 /home/$username/.ssh/authorized_keys

		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may add a user to the system"
	exit 2
fi
