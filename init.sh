#!/bin/bash
APPS=""

function randompass () {
  pass=</dev/urandom tr -dc A-Za-z0-9 | head -c 16
  echo $pass
}

mkdir -p /etc/skel/conf/sites-enabled
mkdir /etc/skel/conf/sites-available
mkdir /etc/skel/public
mkdir /etc/skel/private
mkdir /etc/skel/.run

if [ ! -f "/sbin/createuser" ]; then
  wget -O /sbin/createuser https://raw.github.com/royklopper/production-virtualbox/master/bin/createuser
  chmod +x /sbin/createuser
fi
if [ ! -f "/etc/sysctl.d/60-user.cnf" ]; then
  wget -O /etc/sysctl.d/60-user.cnf https://raw.github.com/royklopper/production-virtualbox/master/sysctl/60-user.cnf
  sysctl -p
fi

echo "Use 1 to enable\n"
echo "Install MySQL? "
read MYSQL

if [ $MYSQL == "1" ]; then
  MYSQLPASS=`randompass`
  percona="/etc/apt/sources.list.d/percona.list"
  if [ ! -f $percona ]; then
    echo "deb http://repo.percona.com/apt quantal main" > $percona
    echo "deb-src http://repo.percona.com/apt quantal main" >> $percona
    apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
  fi
  echo "MySQL root password: $MYSQLPASS"
  APPS="$APPS percona-server-server percona-server-client"
  mkdir /etc/mysql
  wget -O /etc/mysql/my.cnf https://raw.github.com/royklopper/production-virtualbox/master/mysql/my.cnf
  wget -O /etc/mysql/conf.d/optimized.cnf https://raw.github.com/royklopper/production-virtualbox/master/mysql/optimized.cnf
fi

echo "Install PHP? "
read PHP

if [ $PHP == "1" ]; then
  wget -O /etc/skel/conf/php-fpm.conf.dist https://raw.github.com/royklopper/production-virtualbox/master/skel/php-fpm.conf.dist
  APPS="$APPS php5-fpm php5-cli php5-memcache php5-xsl php5-gd php5-curl php5-xmlrpc php5-imagick php5-xcache php5-mysqlnd php-pear php5-mcrypt php5-mhash"
fi

echo "Install Nginx?"
read NGINX

if [ $NGINX == "1" ]; then
  mkdir /etc/nginx
  wget -O /etc/nginx/nginx.conf https://raw.github.com/royklopper/production-virtualbox/master/nginx/nginx.conf
  wget -O /etc/nginx/magento https://raw.github.com/royklopper/production-virtualbox/master/nginx/magento
  wget -O /etc/skel/conf/sites-available/domain.conf https://raw.github.com/royklopper/production-virtualbox/master/skel/domain.conf
  APPS="$APPS nginx-full"
fi

echo "Install Postfix?"
read POSTFIX

if [ $POSTFIX == "1" ]; then
  APPS="$APPS postfix"
fi

apt-get update
apt-get dist-upgrade -y
apt-get install $APPS
apt-get autoremove

locale-gen

apt-get install -y python-software-properties software-properties-common make gcc postfix unrar git-core bash-completion git iotop mytop memcached memcached redis-server unzip

if [ -f /etc/php5/fpm/pool.d/www.conf ]
then
  rm /etc/php5/fpm/pool.d/www.conf
fi

if [ $MYSQL == "1" ]; then
  mysql -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
  mysql -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
  mysql -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"
  mysqladmin -u root password $MYSQLPASS
fi
