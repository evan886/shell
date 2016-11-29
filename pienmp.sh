#!/bin/bash
#添加常用的环境变量
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
# Check  user 4 root 检查是否为最高权限用户
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp and try again"
    exit 1
fi
# by evan886@gmail.com  20150717pm  20150623pm   20130821  这个脚本尽量用了 yum 安装其它不是关键的软件#good  lnmp full 里面的那个升级php的脚本不错呢
#chanlog    update  ImageMagick-7.0.1-5  and imagick-3.4.0 20160519 update openssl-1.0.1p.tar.g  20150716
#./lnmp  2>&1 | tee 36nmp.log  #原版本 lnmp.txt #update 20130204
#提前用yum 安装bzip2 软件，为后面的解压作准备
yum install bzip2 -y

#定义一个变更 在最后面用到 
domain="a.com"
#输出一行红色提醒
echo -e "\033[31m  Please input U domain! Default domain: a.com!!! \033[0m"
#read -p  "\033[31m Please input U domain! Default domain: a.com \033[0m" domain
#读入变量
read domain
#默认domain变量为a.com 
if [ "domain" = " " ]; then
        domain="a.com"
fi
#创建目录和进入目录 ，并下载特定软件包
		mkdir -p /data/tmp/ && cd /data/tmp
		wget -c  linuxchina.net/36nmp.tar.bz2
		#wget -c  yryz.org/36nmp.tar.bz2
                 
               #  4 php 5.3
               #wget linuxchina.net/php-5.3.22.tar.bz2
			   #解压包，并判定是否有php-5.6.6.tar.bz2这个软件包，以确定解压出来的是可用的
		tar -xvf 36nmp.tar.bz2
		if [ -s  /data/tmp/36nmp/php-5.6.6.tar.bz2 ];
		#if [ -s  /data/tmp/36nmp/php-5.3.22.tar.bz2 ];
		then 
		echo "all soft is ok"
		else
		echo " U must to download soft "
		exit 1
		fi
		 dr=/data/tmp/36nmp #定义一个目录，
		cd $dr
		#获取cpu线程数 为编译用上最大的硬件资源，减少make 时间
		cpunu=`cat /proc/cpuinfo |grep  processor |uniq|wc -l`
		#删除自带的httpd  php etc 如果有的话
		yum -y remove httpd*  php*   mysql-server mysql  php-mysql
		#yum -y install yum-fastestmirror #yum -y update
		#Disable SeLinux
		if [ -s /etc/selinux/config ]; then
		sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
		fi
#安装常用的依赖包
for packages in gcc gcc-c++ ncurses-devel libxml2-devel openssl openssl-devel  curl-devel libjpeg-devel libpng-devel autoconf pcre-devel libtool-libs freetype-devel gd  zip unzip wget   file bison cmake patch mlocate flex diffutils automake make  readline-devel   bzip2-devel gettext-devel libcap-devel  ftp wget  ;
#not install 这次拿掉没有安装的软件     logrotate expect openssl openssl-devel crontabs zlib-devel glibc-devel glibc-static glib2-devel 
do 
yum -y install $packages;
done
			#export dr=/data/tmp/36nmp
			cd $dr
#定义一个函数	 inslibiconv，然后三步曲安装	libiconv(configuer  make  make instal ),下面的其它函数相同	
function inslibiconv()
{
	if [ ! -s /usr/local/lib/libiconv.so ]; then
	#if [ ! -d /usr/local/libiconv/bin ]; then
tar xvf libiconv-1.14.tar.bz2 &&  cd libiconv-1.14
./configure --prefix=/usr/local/ 
cd srclib/
sed -i -e '/gets is a security/d' ./stdio.in.h 
cd ../ 
make -j$cpunu && make install
#./configure --prefix=/usr/local/libiconv  && make -j$cpunu && make install
		#./configure  && make -j$cpunu && make install    
	#	： # or echo  "libconv install  completed"
	else 
			echo  "libconv is  installed";
	fi		
}
inslibiconv;

cd $dr
function insmhash
{
tar xvf mhash-0.9.9.9.tar.bz2
cd mhash-0.9.9.9/
./configure 
#./configure --prefix=/usr/local/mhash # 不能加prefix不然下面的安装mcrypt提示没有mhash
make -j$cpunu && make install
}
insmhash;
cd $dr
function inslibmcrypt
{
if [ ! -d /usr/local/libmcrypt ]; then
tar xvf libmcrypt-2.5.8.tar.bz2 && cd libmcrypt-2.5.8/
./configure --prefix=/usr/local/libmcrypt
make -j$cpunu && make install
/sbin/ldconfig
cd libltdl/
./configure --prefix=/usr/local/libmcrypt  --enable-ltdl-install
make -j$cpunu  && make install
fi
#追加
cat >> /etc/ld.so.conf<<EOF
/usr/local/libiconv/lib/
/usr/local/libmcrypt/lib/
/usr/local/lib/
EOF
}
inslibmcrypt;
#别人ln 我直接加到ldconfig
cd $dr
## 这些可以不要用
#ln -s /usr/local/libmcrypt/lib/libmcrypt.la /usr/lib/libmcrypt.la
#ln -s /usr/local/libmcrypt/lib/libmcrypt.so /usr/lib/libmcrypt.so
#ln -s /usr/local/libmcrypt/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
#ln -s /usr/local/libmcrypt/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
#ln -s /usr/local/mhash/lib/libmhash.a /usr/lib/libmhash.a
#ln -s /usr/local/mhash/lib/libmhash.la /usr/lib/libmhash.la
#ln -s /usr/local/mhash/lib/libmhash.so /usr/lib/libmhash.so
#ln -s /usr/local/mhash/lib/libmhash.so.2 /usr/lib/libmhash.so.2
#ln -s /usr/local/mhashs/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1
function insmcrypt
{
tar xvf mcrypt-2.6.8.tar.bz2
cd mcrypt-2.6.8/
#export LD_LIBRARY_PATH=/usr/local/libmcrypt/lib  
#CPPFLAGS="-I/usr/local/libmcrypt/include"
#LDFLAGS="-L/usr/local/libmcrypt/lib -Wl,-rpath,/usr/local/libmcrypt/lib"
./configure --prefix=/usr/local/mcrypt  --with-libmcrypt-prefix=/usr/local/libmcrypt 
make -j$cpunu && make install
}
insmcrypt;
cd $dr

function insngex
{
tar xvf pcre-8.21.tar.bz2 && cd pcre-8.21/ 
./configure  --enable-utf8 --enable-unicode-properties 
make -j$cpunu &&    make  install
cd $dr

tar jxvf zlib-1.2.3.tar.bz2 && cd zlib-1.2.3/
./configure --prefix=/usr/local/zlib 
sed  -i 's/^CFLAGS=.*$/& -fPIC/' Makefile
make -j$cpunu  && make install
cd $dr
#tar xvf openssl-0.9.8o.tar.bz2  && cd openssl-0.9.8o
 tar xvf openssl-1.0.1p.tar.gz  && cd  openssl-1.0.1p
#./config --prefix=/usr/local
./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl
make -j$cpunu && make install
}
insngex;

cd $dr
#http://downloads.mysql.com/archives.php?p=mysql-5.5

# 4 mysql dir 
#mkdir /data/mysql/data
#chown -R mysql:mysql /data/mysql/data

# my.cnf The MySQL server
#[mysqld]
#socket		= /tmp/mysql.sock
#datadir=/data/apps/mysql/data/

function insmysql()
{
	if [ ! -d /usr/local/mysql ]; then
		#tar -xvf mysql-5.5.25.tar.bz2  && cd mysql-5.5.25
                tar -xvf mysql-5.6.32.tar.gz  && cd mysql-5.6.32
		groupadd mysql;
		useradd -s /sbin/nologin -g mysql mysql;
		cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql  -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1  -DWITH_SSL=system -DWITH_ZLIB=system -DWITH_EMBEDDED_SERVER=1;
# -DEXTRA_CHARSETS=all  
		#cmake --help 后要对比一下原来的哦 还有,要对比一下江哥的那个
		#http://forge.mysql.com/wiki/Autotools_to_CMake_Transition_Guide
		make -j4  && make install;
##############################
                 if [ -d  /usr/local/mysql/bin/ ];
                  then
                    echo " mysql sbin is ok "
                  else
                     echo " mysql  sbin is not ok ,exit now "
                     exit 1
                   fi

##############################
		chmod +w /usr/local/mysql; 
		chown -R mysql:mysql /usr/local/mysql;
		#cp support-files/my-medium.cnf /etc/my.cnf
		cp ../conf/my.cnf  /etc/my.cnf
## by evan
#sed -i '29a user=mysql' /etc/my.cnf 
#sed -i '29a character-set-server=utf8' /etc/my.cnf 
#sed -i '29ainnodb_file_per_table=1' /etc/my.cnf 
## by evan 20160710
		/usr/local/mysql/scripts/mysql_install_db --user=mysql --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data;
		cp  support-files/mysql.server /etc/init.d/mysqld
		 chmod 755 /etc/init.d/mysqld
cat >> /etc/ld.so.conf<<EOF
/usr/local/mysql/lib/
EOF
ldconfig;
	SysBit='32';
	if [ `getconf WORD_BIT` == '32' ] && [ `getconf LONG_BIT` == '64' ]; then
		SysBit='64';
	fi;
 if [ "$SysBit" == '64' ] ; then
    ln -s /usr/local/mysql/lib/mysql /usr/lib64/mysql;
	 else
	    ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql;
		 fi;
		 #chmod 775 /usr/local/mysql/support-files/mysql.server;
		 #/usr/local/mysql/support-files/mysql.server start;
		 /etc/init.d/mysqld  start 
		 #这两个加PATH就行了吧
		 #ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql;
		 #ln -s /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin;
		 echo 'export PATH=/usr/local/mysql/bin/:$PATH' >> /etc/profile
		 #echo 'export #PATH=/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:$PATH'  >> /etc/profile
		 . /etc/profile
		 MysqlPass="evan"
		 /usr/local/mysql/bin/mysqladmin password $MysqlPass;
		 rm -rf /usr/local/mysql/data/test;
		 ## EOF  这个安全授权的 下次再搞一下喽**************************************
		# mysql -hlocalhost -uroot -p$MysqlPass <<EOF
		# USE mysql;
		# DELETE FROM user WHERE user='';
		# UPDATE user set password=password('$MysqlPass') WHERE user='root';
		# DELETE FROM user WHERE not (user='root');
		# DROP USER ''@'%';
		# FLUSH PRIVILEGES;
		# EOF
	else
		 echo "mysql is installed";
	fi 	 
}
insmysql;
cd $dr
function insphp()
{
cpunu=`cat /proc/cpuinfo |grep processor |wc -l`
#export dr=/data/tmp/36nmp; cd $dr
if [ ! -d /usr/local/php/bin ]; then
   tar xvf php-5.6.6.tar.bz2 && cd php-5.6.6;
   #tar xvf php-5.3.22.tar.bz2 && cd php-5.3.22;
   groupadd -g 604 www;
   #groupadd -g 504 www;
   useradd -s /sbin/nologin -g www www;
ldconfig;
cp -rp /usr/lib64/mysql/libmysqlclient.so.18.0.0 /usr/lib/libmysqlclient.so
./configure --prefix=/usr/local/php --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --with-openssl=/usr/local/openssl --with-zlib=/usr/local/zlib  --with-curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip  --with-mysql=/usr/local/mysql/  --with-mysqli   --with-mcrypt=/usr/local/libmcrypt --without-pear --with-libxml-dir=/usr --enable-xml --with-mhash  --disable-rpath  --enable-bcmath    --with-pdo-mysql=mysqlnd --with-iconv-dir=/usr/local/    --enable-magic-quotes --enable-safe-mode --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-ftp   --enable-pcntl --enable-sockets --with-xmlrpc  --enable-soap --with-gettext --disable-fileinfo;
#./configure --prefix=/usr/local/php --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --with-openssl=/usr/local/openssl --with-zlib=/usr/local/zlib  --with-curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip  --with-mysql=/usr/local/mysql  --with-mysqli=/usr/local/mysql/bin/mysql_config   --with-mcrypt=/usr/local/libmcrypt --without-pear --with-libxml-dir=/usr --enable-xml --with-mhash  --disable-rpath  --enable-bcmath    --with-pdo-mysql=mysqlnd --with-iconv-dir=/usr/local/    --enable-magic-quotes --enable-safe-mode --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-ftp   --enable-pcntl --enable-sockets --with-xmlrpc  --enable-soap --with-gettext --disable-fileinfo;
# 4 5.3.x http://php.net/manual/en/mysqli.installation.php
#./configure --prefix=/usr/local/php --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --with-openssl=/usr/local/openssl --with-zlib=/usr/local/zlib  --with-curl --enable-ftp --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --enable-gd-native-ttf --enable-mbstring --enable-zip  --with-mysql=/usr/local/mysql  --with-mysqli=mysqlnd  --with-mcrypt=/usr/local/libmcrypt --without-pear --with-libxml-dir=/usr --enable-xml --with-mhash  --disable-rpath  --enable-bcmath    --with-pdo-mysql=mysqlnd --with-iconv-dir=/usr/local/    --enable-magic-quotes --enable-safe-mode --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-ftp   --enable-pcntl --enable-sockets --with-xmlrpc  --enable-soap --with-gettext --disable-fileinfo;
#--with-iconv=/usr/local/libiconv
#sed -i 's/^EXTRA_LIBS =.*/& -liconv/' Makefile
# make -j $cpunu  && make install
 make -j $cpunu ZEND_EXTRA_LIBS='-liconv' && make install
                  if [ -d  /usr/local/php/sbin/ ];
                  then
                    echo " php sbin is ok "
                  else
                     echo " php sbin is not ok ,exit now "
                     exit 1
                   fi
 cd $dr
 \cp php.ini-production5.6  /etc/php.ini
 #\cp php.ini-production5.3  /etc/php.ini
 \cp php-fpm5.4 /etc/rc.d/init.d/php-fpm  ##设置 php-fpm开机启动，拷贝php-fpm到启动目录
 chmod +x /etc/rc.d/init.d/php-fpm  ##添加执行权限  这是自己的,有空再参考一下别人的
 chkconfig php-fpm on
 \cp  php-fpm.conf5.4 /usr/local/php/etc/php-fpm.conf # 4 5.4
# touch /usr/local/php/php-fpm.pid
else 
  echo "php is installed"
 fi
 }
insphp;
cd $dr
function insphpex()
{
#Installing shared extensions:     /usr/local/php/lib/php/extensions/no-debug-non-zts-20090626/
cpunu=`cat /proc/cpuinfo |grep processor |wc -l`
#export dr=/data/tmp/36nmp; cd $dr
cd $dr
# PDO_MYSQL  这个就没安装了 好像 在php5.4里面是不用这个了 ,配置好像有优化 也可以参考一下的
##参考一下新的版本
##here
tar zxvf memcache-3.0.6.tgz && cd memcache-3.0.6
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make -j$cpunu  && make install
cd $dr

tar xvf libevent-2.0.13-stable.tar.bz2
cd libevent-2.0.13-stable/
./configure --prefix=/usr/local/libevent
make&& make install

echo "/usr/local/libevent/lib/" >> /etc/ld.so.conf
#ln -s /usr/local/libevent/lib/libevent-2.0.so.5  /lib/libevent-2.0.so.5
ldconfig
cd $dr
tar xvf memcached-1.4.15.tar.bz2
cd memcached-1.4.15/
./configure --prefix=/usr/local/memcached --with-libevent=/usr/local/libevent/
make &&make install
cd $dr

ln -s  /usr/local/memcached/bin/memcached /usr/bin/memcached

cp memcached-init /etc/init.d/memcached
chmod +x /etc/init.d/memcached
useradd -s /sbin/nologin nobody
/etc/init.d/memcached start

## 和 php5.4会冲突 ,但是php5.3没冲突 git出来的就没事  后面的都放弃了 这个换成最新的
#tar xvf eaccelerator-0.9.6.1.tar.bz2 && cd eaccelerator-0.9.6.1
# cd eaccelerator
#  /usr/local/php/bin/phpize#   ./configure --enable-eaccelerator=shared --with-php-config=/usr/local/php/bin/php-config 
#  make -j$cpunu   && make install
#ImageMagick etc

#tar zxvf eaccelerator-eaccelerator-42067ac.tar.gz
#cd eaccelerator-eaccelerator-42067ac/
#/usr/local/php/bin/phpize
#./configure --enable-eaccelerator=shared --with-php-config=/usr/local/php/bin/php-config
#make  -j$cpunu && make install

cd $dr
#tar xvf ImageMagick.tar.gz 
#cd ImageMagick-6.9.1-8/
tar xvf ImageMagick-7.0.1-5.tar.bz2 
cd ImageMagick-7.0.1-5
./configure --prefix=/usr/local/imagemagick
make -j$cpunu && make install

#https://pecl.php.net/package/imagick
cd $dr
#tar zxvf imagick-3.1.2.tgz
#cd imagick-3.1.2/
tar zxvf imagick-3.4.0.tgz
cd imagick-3.4.0/
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config --with-imagick=/usr/local/imagemagick
make -j$cpunu && make install

cd $dr

mkdir -p  /data/log
chmod 777 -R /data/log
#mkdir -p /usr/local/php/eaccelerator_cache
##pid
#mkdir -p /usr/data/php/eaccelerator_cache
#chmod 0777 /usr/data/php/eaccelerator_cache
	 #export dr=/data/tmp/36nmp
	  cd $dr

#tar zxvf eaccelerator-eaccelerator-42067ac.tar.gz
#cd eaccelerator-eaccelerator-42067ac/
#/usr/local/php/bin/phpize
#./configure --enable-eaccelerator=shared --with-php-config=/usr/local/php/bin/php-config
#make  -j$cpunu && make install
#cd $dr
}
insphpex;
cd $dr
function insnginx()
{
cpunu=`cat /proc/cpuinfo |grep processor |wc -l`
#export dr=/data/tmp/36nmp
cd $dr

	if [ ! -d /usr/local/nginx ]; then
	    #tar xvf nginx-1.2.7.tar.bz2  &&  cd nginx-1.2.7
            tar xvf nginx-1.8.1.tar.gz  &&  cd nginx-1.8.1
            #tar xvf nginx-1.8.0.tar.bz2  &&  cd nginx-1.8.0
	./configure --prefix=/usr/local/nginx --user=www --group=www  --with-http_stub_status_module  --with-pcre=../pcre-8.21 --with-zlib=../zlib-1.2.3 --with-openssl=../openssl-1.0.1p    --without-poll_module    --with-http_ssl_module  --with-http_gzip_static_module  --without-poll_module  --without-http_ssi_module --without-http_userid_module --without-http_geo_module --without-http_memcached_module --without-http_map_module --with-http_realip_module   --without-mail_pop3_module  --without-select_module  --without-mail_imap_module --without-mail_smtp_module --without-http_uwsgi_module --without-http_scgi_module  --with-cc-opt='-O3';
		#make -j $cpunu  &&	make install;
		make   &&	make install;
		  if [ -s  /usr/local/nginx/sbin/nginx ];
		  then
		    echo " nginx sbin is ok "
		  else
		     echo " nginx sbin is not ok ,exit now "
		     exit 1
		   fi
		cd $dr
		\cp nginx /etc/init.d/
		chmod +x /etc/init.d/nginx
		#cd /usr/local/nginx/conf/
	\cp $dr/conf/fastcgi.conf /usr/local/nginx/conf/fcgi.conf 
		cd $dr
             cp /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.confbak
		\cp nginx.conf /usr/local/nginx/conf/
		mkdir -p /usr/local/nginx/conf/hosts
		\cp 1.conf /usr/local/nginx/conf/hosts/
	else 
		echo "nginx is installed"
	fi
}
insnginx;
cd $dr
function other()
{
/etc/init.d/nginx start
/etc/init.d/php-fpm restart
/etc/init.d/mysqld  restart
mkdir -p  /data/www/html_s1/
chown -R www:www /data/www/

#变量定义在最前面嘻嘻 
sed -i "s/server_name.*/server_name $domain;/" /usr/local/nginx/conf/hosts/1.conf
/etc/init.d/nginx reload 

#sed -i '/server_name/ s/.*/server_name  $domain;/g' /usr/local/nginx/conf/hosts/1.conf
#sed -i "s/server_name.*/server_name $domain;/" 1.conf
#sed -i "s/MEMCACHE_HOST'.*)/MEMCACHE_HOST','1.182.30.105')/" 
#sed -i '/HOSTNAME/ s/.*/HOSTNAME=notuse/g' /etc/sysconfig/network && hostname notuse &&export HOSTNAME=notuse

#export dr=/data/tmp/36nmp
cd $dr
chkconfig --level 345 php-fpm on
chkconfig --level 345 nginx on
chkconfig --level 345 mysqld on
}
other;

cd $dr
#good  lnmp full 里面的那个升级php的脚本不错呢
#http://blog.chinaunix.net/uid-9419692-id-3200819.html
#http://www.linuxidc.com/Linux/2011-07/38107p2.htm?1352725125
#http://www.oschina.net/question/189490_31185
#http://www.oschina.net/question/91955_29432
