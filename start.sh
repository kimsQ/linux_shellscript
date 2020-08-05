#!/bin/bash
# Amazon_Linux kimsQ Rb2 전용서버 구성 쉘스크립트
# -------------------------------------------------------------------------
# See url for more info:
# https://kimsq.com/docs/c/start/install/59/60

# APM 설치
yum update -y
yum install -y httpd24 php73 mysql57-server php73-mysqlnd
service httpd start
service mysqld start
chkconfig httpd on
chkconfig mysqld on

#인스턴스 기본계정 권한부여
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www

# phpMyAdmin 설치
yum install php73-mbstring.x86_64 -y
cd /var/www/html
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
mkdir phpMyAdmin && tar -xvzf phpMyAdmin-latest-all-languages.tar.gz -C phpMyAdmin --strip-components 1
chown -R ec2-user:ec2-user *
rm phpMyAdmin-latest-all-languages.tar.gz

# git & expect 설치
yum install -y git
yum install -y expect

# 웹서버 확장모듈 설치(ruid2,mod24_ssl)
cd /home/ec2-user
git clone https://github.com/mind04/mod-ruid2.git
yum install -y httpd24-devel.x86_64  libcap-devel gcc
cd mod-ruid2
apxs -a -i -l cap -c ./mod_ruid2.c
rm -rf /home/ec2-user/mod-ruid2
yum install -y mod24_ssl

# PHP GD 라이브러리 설치
yum install -y php73-gd

# vsftpd 설치/설정
yum install -y vsftpd
sed -i 's,^anonymous_enable=.*$,anonymous_enable=NO,'  /etc/vsftpd/vsftpd.conf
sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/g' /etc/vsftpd/vsftpd.conf
sed -i '$a\pasv_enable=YES' /etc/vsftpd/vsftpd.conf
sed -i '$a\pasv_min_port=1024' /etc/vsftpd/vsftpd.conf
sed -i '$a\pasv_max_port=1048' /etc/vsftpd/vsftpd.conf
/etc/init.d/vsftpd start
chkconfig vsftpd on

# 시스템 시간 설정
rm /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# PHP 설정
echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
sed -i 's/;date.timezone =/date.timezone = Asia\/Seoul/g' /etc/php.ini
sed -i 's/^allow_url_fopen =.*$,allow_url_fopen = off/g' /etc/php.ini
sed -i 's/^upload_max_filesize =.*$,upload_max_filesize = 20M/g' /etc/php.ini
sed -i 's/^post_max_size =.*$,post_max_size = 20M/g' /etc/php.ini
sed -i 's/^max_execution_time =.*$,max_execution_time = 30/g' /etc/php.ini
sed -i 's/^max_file_uploads =.*$,max_file_uploads = 20/g'  /etc/php.ini
chown -R ec2-user:ec2-user /var/www/html/phpinfo.php

# 웹서버 홈디렉토리 설정
echo "#User Directory Setting" > /etc/httpd/conf.d/default.conf
sed -i '$a\<Directory /home/*/www>' /etc/httpd/conf.d/default.conf
sed -i '$a\ AllowOverride All' /etc/httpd/conf.d/default.conf
sed -i '$a\ Require all granted' /etc/httpd/conf.d/default.conf
sed -i '$a\</Directory>' /etc/httpd/conf.d/default.conf
sed 's/regexp/\'$'\n/g' /etc/httpd/conf.d/default.conf
sed -i '$a\<VirtualHost *:80>' /etc/httpd/conf.d/default.conf
sed -i '$a\ DocumentRoot /var/www/html' /etc/httpd/conf.d/default.conf
sed -i '$a\ ServerName 192.168.0.1' /etc/httpd/conf.d/default.conf
sed -i '$a\</VirtualHost>' /etc/httpd/conf.d/default.conf
echo "#VirtualHost Setting" > /etc/httpd/conf.d/vhost.conf

# Let's Encrypt 인증서 에이전트 설치
yum-config-manager --enable epel
cd /home/ec2-user
wget https://dl.eff.org/certbot-auto
chmod a+x certbot-auto

# 관리용 쉘스크립트 다운로드
wget -O adduser-auto https://raw.githubusercontent.com/kimsQ/linux_shellscript/master/adduser-auto.sh
wget -O virtualhost-auto https://raw.githubusercontent.com/kimsQ/linux_shellscript/master/virtualhost-auto.sh
chmod +x virtualhost-auto
chmod +x adduser-auto

#mysql 보안설정
openssl rand -base64 10 > MYSQL_ROOT_PASSWORD
MYSQL_ROOT_PASSWORD=$(cat /home/ec2-user/MYSQL_ROOT_PASSWORD)
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Would you like to setup VALIDATE PASSWORD component?\"
send \"n\r\"
expect \"New password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

#인증서 갱신 스케줄러 설정
sed -i '$a\39      1,13    *       *       *       root    certbot renew --no-self-upgrade' /etc/crontab

# 재시작
service httpd restart
service mysqld restart
service crond restart

# 설치완료 페이지 출력
cd /var/www/html
wget https://raw.githubusercontent.com/kimsQ/linux_shellscript/master/index.html
chown -R ec2-user:ec2-user index.html
