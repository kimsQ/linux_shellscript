#!/bin/bash

ok() { echo -e '\e[32m'$1'\e[m'; } # Green

### Set Language
TEXTDOMAIN=virtualhost

### Set default parameters
action=$1
domain=$2
owner=$3
sitesAvailable='/etc/httpd/conf.d/'
homeDir='/home/'
sitesAvailabledomain=$sitesAvailable$domain.conf
sitesAvailableSSLdomain=$sitesAvailable$domain-le-ssl.conf

### don't modify from here unless you know what you are doing ####

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'delete' ]
	then
		echo $"You need to prompt for action (create or delete) -- Lower-case only"
		exit 1;
fi

while [ "$domain" == "" ]
do
	echo -e $"Please provide domain. e.g.dev,staging"
	read domain
done

if [ "$owner" == "" ] && [ "$action" == 'create' ]
	then
		echo $"Please provide owner"
		exit 1;
fi

rootDir=$homeDir$owner/www

if [ "$action" == 'create' ]
	then
		### check if domain already exists
		if [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain already exists.\nPlease Try Another one"
			exit;
		fi

		echo "Do you wish to add  www.$domain?"
		select yn in "Yes" "No"; do
		    case $yn in
					Yes )
					if ! echo "
					<VirtualHost *:80>
						ServerName $domain
						ServerAlias www.$domain
						DocumentRoot $rootDir
						RMode config
						RUidGid $owner apache
						<Directory $rootDir>
						  AllowOverride All
					    Require all granted
						</Directory>
						ErrorLog /var/log/httpd/$domain-error.log
						LogLevel error
						CustomLog /var/log/httpd/$domain-access.log combined
					</VirtualHost>" > $sitesAvailabledomain
					then
						echo -e $"There is an ERROR creating $domain file"
						exit;
					else
						echo -e $"\nNew Virtual Host Created\n"
					fi
					break;;

					No )
					if ! echo "
					<VirtualHost *:80>
						ServerName $domain
						DocumentRoot $rootDir
						RMode config
						RUidGid $owner apache
						<Directory $rootDir>
						  AllowOverride All
					    Require all granted
						</Directory>
						ErrorLog /var/log/httpd/$domain-error.log
						LogLevel error
						CustomLog /var/log/httpd/$domain-access.log combined
					</VirtualHost>" > $sitesAvailabledomain
					then
						echo -e $"There is an ERROR creating $domain file"
						exit;
					else
						echo -e $"\nNew Virtual Host Created\n"
					fi
					break;;

				esac
		done

		if [ "$owner" == "" ]; then
			chown -R $user:$user $rootDir
		else
			chown -R $owner:$owner $rootDir
		fi

		### restart Apache
    service httpd restart

		### show the finished message
		ok "Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $rootDir"
		exit;
	else
		### check whether domain already exists
		if ! [ -e $sitesAvailabledomain ]; then
			echo -e $"This domain does not exist.\nPlease try another one"
			exit;
		else

			### Delete virtual host rules files
			rm $sitesAvailabledomain

			if [ -e $sitesAvailableSSLdomain ]; then
				rm $sitesAvailableSSLdomain
			fi

			### restart Apache
			service httpd restart

		fi

		### show the finished message
		ok "Complete!\nYou just removed Virtual Host $domain"
		exit 0;
fi
