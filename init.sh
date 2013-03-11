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

apt-get install -y python-software-properties software-properties-common
apt-get install -y make gcc postfix unrar git-core bash-completion subversion git iotop mytop nginx-full memcached libmysqlclient18
apt-get install -y php5-fpm php5-cli php5-suhosin php5-xsl php5-gd php5-curl php5-xmlrpc libmagick-dev imagemagick libmagickwand-dev
apt-get install -y php5-xcache php5-xdebug php5-mysqlnd php-pear php5-mcrypt php5-mhash libmcrypt-dev mcrypt php5-dev php5-memcache

wget -O /etc/nginx/nginx.conf https://raw.github.com/royklopper/production-virtualbox/master/nginx/nginx.conf
wget -O /etc/nginx/magento https://raw.github.com/royklopper/production-virtualbox/master/nginx/magento
wget -O /etc/php5/fpm/php-fpm.conf https://raw.github.com/royklopper/production-virtualbox/master/php5/php-fpm.conf
wget -O /etc/mysql/my.cnf https://raw.github.com/royklopper/production-virtualbox/master/mysql/my.cnf
wget -O /etc/mysql/conf.d/optimized.cnf https://raw.github.com/royklopper/production-virtualbox/master/mysql/optimized.cnf   
wget -O /etc/sysctl.d/60-user.cnf https://raw.github.com/royklopper/production-virtualbox/master/sysctl/60-user.cnf   

if [ -f /etc/php5/fpm/pool.d/www.conf ]
then
  rm /etc/php5/fpm/pool.d/www.conf 
fi

apt-get install -y percona-server-server percona-server-client

service postfix restart
service nginx restart
service php5-restart
service mysql restart

