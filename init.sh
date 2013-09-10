locale-gen nl_NL.UTF-8#!/bin/bash
APPS=""

function randompass () {
  pass=</dev/urandom tr -dc A-Za-z0-9 | head -c 16
  echo $pass
}

if [ ! -d /etc/skel/conf/sites-enabled ]; then
  mkdir -p /etc/skel/conf/sites-enabled
fi
if [ ! -d /etc/skel/conf/sites-available ]; then
  mkdir /etc/skel/conf/sites-available
fi
if [ ! -d /etc/skel/public ]; then
  mkdir /etc/skel/public
fi
if [ ! -d /etc/skel/private ]; then
  mkdir /etc/skel/private
fi
if [ ! -d /etc/skel/.run ]; then
  mkdir /etc/skel/.run
fi

apt-get install -y python-software-properties software-properties-common

if [ ! -f "/sbin/createuser" ]; then
  wget -q -O /sbin/createuser https://raw.github.com/royklopper/production-virtualbox/master/bin/createuser
  chmod +x /sbin/createuser
fi
if [ ! -f "/etc/sysctl.d/60-user.cnf" ]; then
  wget -q -O /etc/sysctl.d/60-user.cnf https://raw.github.com/royklopper/production-virtualbox/master/sysctl/60-user.cnf
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
  APPS="$APPS percona-server-server percona-server-client mysqltuner"
  mkdir -p /etc/mysql/conf.d
  wget -q -O /etc/mysql/my.cnf https://raw.github.com/royklopper/production-virtualbox/master/mysql/my.cnf
  wget -q -O /etc/mysql/conf.d/optimized.cnf https://raw.github.com/royklopper/production-virtualbox/master/mysql/optimized.cnf
fi

echo "Install PHP? "
read PHP

if [ $PHP == "1" ]; then
  wget -q -O /etc/skel/conf/php-fpm.conf.dist https://raw.github.com/royklopper/production-virtualbox/master/skel/php-fpm.conf.dist
  APPS="$APPS php5-fpm php5-cli php5-memcache php5-xsl php5-gd php5-curl php5-xmlrpc php5-imagick php5-xcache php5-mysqlnd php-pear php5-mcrypt php5-mhash"
fi

echo "Install Nginx?"
read NGINX

if [ $NGINX == "1" ]; then
  mkdir /etc/nginx
  wget -q -O /etc/nginx/nginx.conf https://raw.github.com/royklopper/production-virtualbox/master/nginx/nginx.conf
  wget -q -O /etc/nginx/magento https://raw.github.com/royklopper/production-virtualbox/master/nginx/magento
  wget -q -O /etc/skel/conf/sites-available/domain.conf https://raw.github.com/royklopper/production-virtualbox/master/skel/domain.conf
  APPS="$APPS nginx-full"
fi

echo "Install Postfix?"
read POSTFIX

if [ $POSTFIX == "1" ]; then
  APPS="$APPS postfix"
fi

echo "Install Memcached?"
read MEMCACHED

if [ $MEMCACHED == "1" ]; then
  APPS="$APPS memcached"
  if [ $PHP == "1" ]; then
    APPS="$APPS php5-memcache"
  fi
fi

echo "Install Redis?"
read REDIS

if [ $REDIS == "1" ]; then
  APPS="$APPS redis-server"
  add-apt-repository -y ppa:chris-lea/redis-server
fi


apt-get update
apt-get dist-upgrade -y
apt-get install -y $APPS make gcc unrar git-core bash-completion git iotop mytop unzip
apt-get autoremove

locale-gen
locale-gen nl_NL.UTF-8

if [ -f /etc/php5/fpm/pool.d/www.conf ]
then
  rm /etc/php5/fpm/pool.d/www.conf
fi

if [ $PHP == "1" ]; then
  service php5-fpm restart
fi

if [ $NGINX == "1" ]; then
  service nginx start
fi

if [ $REDIS == "1" -a $PHP == "1" ]; then
  wget -O /root/phpredis.zip https://github.com/nicolasff/phpredis/archive/master.zip
  cd /root
  unzip phpredis.zip
  cd phpredis-master
  phpize
  ./configure
  make && make install
  echo 'extension=redis.so' > /etc/php5/conf.d/redis.ini
  service php5-fpm restart
fi

if [ $MYSQL == "1" ]; then
  mysql -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
  mysql -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
  mysql -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"
  mysqladmin -u root password $MYSQLPASS
  echo "MySQL root password: $MYSQLPASS"
fi
