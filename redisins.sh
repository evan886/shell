#!/bin/bash
#Author evan


#redis ins
mdkir -p /data/evan/
cd /data/evan/
wget -c http://download.redis.io/releases/redis-3.0.0.tar.gz
tar xvf redis-3.0.0.tar.gz 
cd redis-3.0.0
make -j2
make  install 

mkdir /etc/redis
cp redis.conf /etc/redis/redis.conf
echo "vm.overcommit_memory=1">>/etc/sysctl.conf
sysctl -p
redis-server /etc/redis/redis.conf  &


#phpredis ins
cd /data/evan/
wget --no-check-certificate  https://github.com/nicolasff/phpredis/archive/master.zip
mdkir -p /data/evan/


unzip master 
cd /data/evan/phpredis-master/
phpize 
./configure  -with-php-config=/usr/bin/php-config

make -j3 && make install 


echo 'extension="redis.so"' >>/etc/php.ini

#vim /etc/php.ini


