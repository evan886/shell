#!/bin/bash
#Author evan
#changelog  添加一些变量 和改正写错的一些命令 
## 这个脚本不一定通用哦 虽然我尽量用了变量 去定义phpize php-conf php.ini etc


#redis ins
mkdir -p /data/evan/
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
mkdir -p /data/evan/


unzip master 
cd /data/evan/phpredis-master/

PHPIZE=$(find  / -name phpize |awk '{print $1}')
$PHPIZE

myphpconf=$(find  / -name php-config|sed -n 1p )
./configure  -with-php-config=$myphpconf

make -j3 && make install 


myphpini=$(find  / -name php.ini|sed -n 1p )
echo 'extension="redis.so"' >>$myphpini

