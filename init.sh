#!/bin/bash

percona='/etc/apt/sources.list.d/percona.list'

if [ ! -f $percona ]
then
  echo 'deb http://repo.percona.com/apt quantal main' > $percona
  echo 'deb-src http://repo.percona.com/apt quantal main' >> $percona

  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 94558F59
  gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
  gpg -a --export CD2EFD2A | sudo apt-key add -
fi
apt-get update
apt-get dist-upgrade -y
apt-get autoremove

apt-get install -y python-software-properties software-properties-common \
                   make gcc postfix unrar git-core bash-completion git iotop mytop nginx-full memcached \
                   php5-fpm php5-cli php5-memcache php5-xsl php5-gd php5-curl php5-xmlrpc php5-imagick \
                   php5-xcache php5-mysqlnd php-pear php5-mcrypt php5-mhash inotify-tools \
                   percona-server-server percona-server-client

wget -O /etc/nginx/nginx.conf https://raw.github.com/royklopper/production-virtualbox/master/nginx/nginx.conf
wget -O /etc/nginx/magento https://raw.github.com/royklopper/production-virtualbox/master/nginx/magento
wget -O /etc/php5/fpm/php-fpm.conf https://raw.github.com/royklopper/production-virtualbox/master/php5/php-fpm.conf
wget -O /etc/mysql/my.cnf https://raw.github.com/royklopper/production-virtualbox/master/mysql/my.cnf
wget -O /etc/mysql/conf.d/optimized.cnf https://raw.github.com/royklopper/production-virtualbox/master/mysql/optimized.cnf
wget -O /etc/sysctl.d/60-user.cnf https://raw.github.com/royklopper/production-virtualbox/master/sysctl/60-user.cnf

mkdir -p /etc/skel/conf/sites-enabled
mkdir /etc/skel/conf/sites-available
mkdir /etc/skel/public
mkdir /etc/skel/private

wget -O /etc/skel/conf/sites-available/domain.conf https://raw.github.com/royklopper/production-virtualbox/master/skel/domain.conf
wget -O /etc/skel/conf/php-fpm.conf.dist https://raw.github.com/royklopper/production-virtualbox/master/skel/php-fpm.conf.dist

if [ -f /etc/php5/fpm/pool.d/www.conf ]
then
  rm /etc/php5/fpm/pool.d/www.conf
fi

service postfix restart
service nginx restart
service php5-restart
service mysql restart

