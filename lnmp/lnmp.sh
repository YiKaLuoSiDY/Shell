#!/bin/bash

INSTALL_PATH="/usr/local/lnmp"
SRC_PATH="$INSTALL_PATH/src"

NGINX_PATH="$INSTALL_PATH/nginx-1.20.0"
LIBZIP_PATH="$INSTALL_PATH/libzip-1.3.2"
ONIGURUMA_PATH="$INSTALL_PATH/oniguruma-6.9.4"
PHP_PATH="$INSTALL_PATH/php-8.2.3"
MYSQL_PATH="$INSTALL_PATH/mysql-8.1.0"

err_dis() {
    [ $? = 0 ] || { echo -e "\033[31m$1\033[0m" ; exit 1; }
}
file_exist() {
    [ -f "$1" ]
}



[ ! -d "$INSTALL_PATH" ]
err_dis "目录${INSTALL_PATH}已存在,需要手动删除!"

# wget
URL1="http://nginx.org/download/nginx-1.20.0.tar.gz"
URL2="https://raw.githubusercontent.com/YiKaLuoSiDY/Shell/main/lnmp/conf/libzip-1.3.2.tar.gz"
URL3="https://raw.githubusercontent.com/YiKaLuoSiDY/Shell/main/lnmp/conf/oniguruma-6.9.4.tar.gz"
URL4="https://www.php.net/distributions/php-8.2.3.tar.gz"
URL5="https://downloads.mysql.com/archives/get/p/23/file/mysql-8.1.0-linux-glibc2.17-x86_64.tar.xz"

URL6="https://raw.githubusercontent.com/YiKaLuoSiDY/Shell/main/lnmp/conf/nginx.conf"
URL7="https://raw.githubusercontent.com/YiKaLuoSiDY/Shell/main/lnmp/conf/vhosts_80.conf"
URL8="https://raw.githubusercontent.com/YiKaLuoSiDY/Shell/main/lnmp/conf/www.conf"
URL9="https://raw.githubusercontent.com/YiKaLuoSiDY/Shell/main/lnmp/conf/my.cnf"

cd /root
for i in {1..9}
do
    eval URL=\$URL$i
    FILE=$(echo $URL | awk -F '[/]' '{print $NF}')
    file_exist "$FILE" || wget $URL
    err_dis "${FILE}下载失败！"
done
mkdir -p $SRC_PATH

# nginx
cd /root
yum install make curl-devel libxml2-devel libjpeg-devel freetype-devel gd-devel gcc gcc-c++ geoip-devel xinetd pcre pcre-devel libxslt-devel postfix -y
err_dis "nginx依赖安装失败！"
tar zxf nginx-1.20.0.tar.gz -C $SRC_PATH
err_dis "nginx-1.20.0.tar.gz解压失败！"
cd $SRC_PATH/nginx-1.20.0
./configure \
    --with-threads \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_degradation_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --with-stream=dynamic \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-stream_ssl_preread_module \
    --with-compat  \
    --with-pcre-jit \
    --prefix=${NGINX_PATH}
err_dis "nginx配置失败！"
make -j8
err_dis "nginx编译失败！"
make install
err_dis "nginx安装失败！"
mv $NGINX_PATH/html $NGINX_PATH/www
mkdir -p $NGINX_PATH/conf/conf.d/vhosts
echo "export PATH=\$PATH:$NGINX_PATH/sbin" >> /etc/profile
source /etc/profile
mv $NGINX_PATH/conf/nginx.conf $NGINX_PATH/conf/nginx.conf.bak
mv /root/nginx.conf $NGINX_PATH/conf/
mv /root/vhosts_80.conf $NGINX_PATH/conf/conf.d/vhosts/
sed -i "s|\$NGINX_PATH|$NGINX_PATH|g" $NGINX_PATH/conf/nginx.conf
sed -i "s|\$NGINX_PATH|$NGINX_PATH|g" $NGINX_PATH/conf/conf.d/vhosts/vhosts_80.conf

# libzip
cd /root
tar zxf libzip-1.3.2.tar.gz -C $SRC_PATH
err_dis "libzip-1.3.2.tar.gz解压失败！"
cd $SRC_PATH/libzip-1.3.2
./configure --prefix=${LIBZIP_PATH}
err_dis "libzip配置失败！"
make -j8
err_dis "libzip编译失败！"
make install
err_dis "libzip安装失败！"

# oniguruma
cd /root
yum -y install libtool
err_dis "oniguruma依赖安装失败！"
tar zxf oniguruma-6.9.4.tar.gz -C $SRC_PATH
err_dis "oniguruma-6.9.4.tar.gz解压失败！"
cd $SRC_PATH/oniguruma-6.9.4
./autogen.sh
err_dis "oniguruma环境准备失败！"
./configure --prefix=${ONIGURUMA_PATH}
err_dis "oniguruma配置失败！"
make -j8
err_dis "oniguruma编译失败！"
make install
err_dis "oniguruma安装失败！"

# php
cd /root
echo "export PKG_CONFIG_PATH=${LIBZIP_PATH}/lib/pkgconfig:${ONIGURUMA_PATH}/lib/pkgconfig" >> /etc/profile
source /etc/profile
yum install sqlite-devel bzip2-devel libcurl-devel libicu-devel -y
err_dis "php环境安装失败！"
tar zxf php-8.2.3.tar.gz -C $SRC_PATH
err_dis "php-8.2.3.tar.gz解压失败！"
cd $SRC_PATH/php-8.2.3
./configure \
    --with-curl \
    --with-freetype \
    --enable-gd \
    --with-jpeg \
    --with-gettext \
    --with-kerberos \
    --with-libdir=lib64 \
    --with-libxml \
    --with-mysqli \
    --with-openssl \
    --with-pdo-mysql \
    --with-pdo-sqlite \
    --with-pear \
    --enable-sockets \
    --with-mhash \
    --with-ldap-sasl \
    --with-xsl \
    --with-zlib \
    --with-zip \
    --with-bz2 \
    --with-iconv \
    --enable-fpm \
    --enable-pdo \
    --enable-bcmath \
    --enable-mbregex \
    --enable-mbstring \
    --enable-opcache \
    --enable-pcntl \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-sysvsem \
    --enable-xml \
    --enable-sysvsem \
    --enable-cli \
    --enable-opcache \
    --enable-intl \
    --enable-calendar \
    --enable-static \
    --enable-mysqlnd \
    --prefix=${PHP_PATH} \
    --with-config-file-path=${PHP_PATH}/etc
err_dis "php配置失败！"
make -j8
err_dis "php编译失败！"
make install
err_dis "php安装失败！"
mv $PHP_PATH/etc/php-fpm.conf.default $PHP_PATH/etc/php-fpm.conf
mkdir $PHP_PATH/{run,log}
echo "export PATH=\$PATH:$PHP_PATH/bin" >> /etc/profile
source /etc/profile
mv /root/www.conf $PHP_PATH/etc/php-fpm.d/
sed -i "s|\$PHP_PATH|$PHP_PATH|g" $PHP_PATH/etc/php-fpm.d/www.conf
id www &>/dev/null || useradd www -s /sbin/nologin
chown www.www -R $NGINX_PATH
chown www.www -R $PHP_PATH

# mysql
cd /root
xz -d mysql-8.1.0-linux-glibc2.17-x86_64.tar.xz
tar xf mysql-8.1.0-linux-glibc2.17-x86_64.tar
mv mysql-8.1.0-linux-glibc2.17-x86_64 $MYSQL_PATH
mkdir $MYSQL_PATH/{logs,etc,data}
rm -f $MYSQL_PATH/{LICENSE,README}
mv /root/my.cnf $MYSQL_PATH/etc/
sed -i "s|\$MYSQL_PATH|$MYSQL_PATH|g" $MYSQL_PATH/etc/my.cnf
id mysql &>/dev/null || useradd mysql -s /sbin/nologin
chown mysql.mysql -R $MYSQL_PATH
echo "export PATH=\$PATH:$MYSQL_PATH/bin" >> /etc/profile
echo "export MYSQL_HOME=$MYSQL_PATH/etc" >> /etc/profile
source /etc/profile
$MYSQL_PATH/bin/mysqld \
  --defaults-file=$MYSQL_PATH/etc/my.cnf \
  --basedir=$MYSQL_PATH \
  --datadir=$MYSQL_PATH/data \
  --user=mysql --initialize
err_dis "数据库初始化失败,查看错误信息！"
MYSQL_PASSWORD=$(grep -w 'root@localhost' $MYSQL_PATH/logs/mysql.err | awk '{print $NF}')

# start
echo -e "\n\033[32m// 启动 nignx、php、mysql\033[0m"
$NGINX_PATH/sbin/nginx -c $NGINX_PATH/conf/nginx.conf
sleep 1
netstat -lntpu | grep "nginx" | grep -w tcp

$PHP_PATH/sbin/php-fpm -c $PHP_PAHT/etc/php-fpm.conf
sleep 1
netstat -lntpu | grep "php" | grep -w tcp

$MYSQL_PATH/bin/mysqld --defaults-file=${MYSQL_PATH}/etc/my.cnf &
sleep 1
netstat -lntpu | grep "mysql" | grep -w tcp

# echo
echo -e "\033[32m// 需要修改mysql临时密码\033[0m
┌───────────────────────────────────────────────────────────
 | 临时密码：$MYSQL_PASSWORD
 | $MYSQL_PATH/bin/mysql -u root -p
 | ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';
└───────────────────────────────────────────────────────────
\033[32m// 如出现以下报错，重新打开终端窗口登录\033[0m
Can't connect to local MySQL server through socket
"

# clear
cd /root
rm -f ./libzip-1.3.2.tar.gz
rm -f ./nginx-1.20.0.tar.gz
rm -f ./oniguruma-6.9.4.tar.gz
rm -f ./php-8.2.3.tar.gz
rm -f ./mysql-8.1.0-linux-glibc2.17-x86_64.tar
