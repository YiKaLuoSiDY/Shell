#!/bin/bash

# 定义应用安装目录
INSTALL_PATH="/usr/local/prometheus"
PROMETHEUS_PATH="$INSTALL_PATH/prometheus-2.45.2"
REDIS_EXPORTER_PATH="$INSTALL_PATH/redis_exporter-1.47.0"
NODE_EXPORTER_PATH="$INSTALL_PATH/node_exporter-1.7.0"

failure() {
    echo -en "\\033[60G[\\033[1;31mFAILED\\033[0;39m]\r"
}

# 判断命令是否执行失败 函数
if_failure() {
    if [ $? -ne 0 ]; then
        echo -en "$1"
        failure ; echo
        exit 1
    fi
}

# centos6系统启动配置下载 函数
centos6_start_service() {
    # 下载 prometheus 启动配置
    wget -P /etc/init.d/ https://raw.githubusercontent.com/YiKaLuoSiDY/cong/main/prometheus
    if_failure "prometheus 启动配置下载失败"
    sed -i "s/\$PROMETHEUS_PATH/$PROMETHEUS_PATH/g" /etc/init.d/prometheus

    # 下载 node_exporter 启动配置
    wget -P /etc/init.d/ https://raw.githubusercontent.com/YiKaLuoSiDY/cong/main/node_exporter
    if_failure "node_exporter 启动配置下载失败"
    sed -i "s/\$NODE_EXPORTER_PATH/$NODE_EXPORTER_PATH/g" /etc/init.d/node_exporter

    # 添加执行权限
    chmod +x /etc/init.d/{prometheus,node_exporter}
}

# centos7系统启动配置生成 函数
centos7_start_service() {
    # prometheus 启动配置
    cat > /usr/lib/systemd/system/prometheus.service << EOF
[Unit]
Description=https://prometheus.io
[Service]
ExecStart=$PROMETHEUS_PATH/bin/prometheus \\
  --storage.tsdb.path=$PROMETHEUS_PATH/data \\
  --config.file=$PROMETHEUS_PATH/conf/prometheus.yml \\
  --web.listen-address=:9099
[Install]
EOF
    # node_exporter 启动配置
    cat > /usr/lib/systemd/system/node_exporter.service << EOF
[Unit]
Description=Prometheus node_exporter
[Service]
ExecStart=$NODE_EXPORTER_PATH/node_exporter \\
  --web.listen-address=:9100
[Install]
EOF
}



# 检查
if [ -d "$INSTALL_PATH" ]; then
    echo "Installation directory "$INSTALL_PATH" exists, need to delete directory manually!"
    exit 1
else
    rpm -qa | grep grafana && {
        echo "grafana is already installed, so you'll need to uninstall it manually"
        exit 1
        }
fi

# 准备工作
# 下载安装包
cd /root
wget https://github.com/prometheus/prometheus/releases/download/v2.45.2/prometheus-2.45.2.linux-amd64.tar.gz
if_failure "prometheus-2.45.2.linux-amd64.tar.gz 下载失败"
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
if_failure "node_exporter-1.7.0.linux-amd64.tar.gz 下载失败"
wget https://github.com/oliver006/redis_exporter/releases/download/v1.47.0/redis_exporter-v1.47.0.linux-amd64.tar.gz
if_failure "redis_exporter-v1.47.0.linux-amd64.tar.gz 下载失败"
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-8.5.2-1.x86_64.rpm
if_failure "grafana-enterprise-8.5.2-1.x86_64.rpm 下载失败"
# 创建安装目录
mkdir $INSTALL_PATH

# 脚本主体
# 安装 prometheus
tar zxf prometheus-2.45.2.linux-amd64.tar.gz -C $INSTALL_PATH
if_failure "prometheus 安装失败"
mv $INSTALL_PATH/prometheus-2.45.2.linux-amd64 $PROMETHEUS_PATH
rm -f $PROMETHEUS_PATH/{LICENSE,NOTICE}
mkdir $PROMETHEUS_PATH/bin
mkdir -p $PROMETHEUS_PATH/conf/conf.d
mv $PROMETHEUS_PATH/{prometheus,promtool} $PROMETHEUS_PATH/bin
mv $PROMETHEUS_PATH/prometheus.yml $PROMETHEUS_PATH/conf

# 安装 redis_exporter
tar zxf redis_exporter-v1.47.0.linux-amd64.tar.gz -C $INSTALL_PATH
if_failure "redis_exporter 安装失败"
mv $INSTALL_PATH/redis_exporter-v1.47.0.linux-amd64 $REDIS_EXPORTER_PATH
rm -f $REDIS_EXPORTER_PATH/{LICENSE,README.md}
mkdir $REDIS_EXPORTER_PATH/bin
mv $REDIS_EXPORTER_PATH/redis_exporter $REDIS_EXPORTER_PATH/bin

# 安装 node_exporter
tar zxf node_exporter-1.7.0.linux-amd64.tar.gz -C $INSTALL_PATH
if_failure "node_exporter 安装失败"
mv $INSTALL_PATH/node_exporter-1.7.0.linux-amd64 $NODE_EXPORTER_PATH
rm -f $NODE_EXPORTER_PATH/{LICENSE,NOTICE}
chown root.root -R $INSTALL_PATH

# 安装 grafana
yum -y install grafana-enterprise-8.5.2-1.x86_64.rpm
if_failure "grafana 安装失败"

# 添加开机启动
REDHAT_RELEASE=$(cat /etc/redhat-release)
# 使用正则表达式匹配版本号
if [[ "$REDHAT_RELEASE" =~ "CentOS release 6" ]]; then
    centos6_start_service
    chkconfig --add prometheus
    chkconfig --add node_exporter
    chkconfig --level 2345 prometheus
    chkconfig --level 2345 node_exporter
    chkconfig --level 2345 grafana-server
elif [[ "$REDHAT_RELEASE" =~ "CentOS Linux release 7" ]]; then
    # 使 grafana 进程可以被kill杀死
    sed -i 's/Restart=on-failure/Restart=no/g' /usr/lib/systemd/system/grafana-server.service
    systemctl daemon-reload
    centos7_start_service
    systemctl daemon-reload
    systemctl enable prometheus
    systemctl enable node_exporter
    systemctl enable grafana-server
else
    echo "This is not CentOS 6 or 7. It might be another version or OS."
fi

# 清理
clear() {
    cd /root
    rm -f ./prometheus-2.45.2.linux-amd64.tar.gz
    rm -f ./node_exporter-1.7.0.linux-amd64.tar.gz
    rm -f ./redis_exporter-v1.47.0.linux-amd64.tar.gz
    rm -f ./grafana-enterprise-8.5.2-1.x86_64.rpm
}
clear
