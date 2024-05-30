#!/bin/bash
# 此脚本实现 redis_exporter 启动脚本的自动配置、prometheus 热加载文件的自动配置
# 执行脚本需要定义以下变量:
#     BUSINESS_SERVICE_NAME // 业务的名称（用于创建存放目录、生成的文件的命名）
#     ROOM_NAME_DATA_CENTER // 机房的名称（用于创建存放目录、生成的文件的命名）
#     REDIS_LIST            // 集群各节点（ip:port 用于配置生成文件）
#     REDIS_PASSWORD        // redis的密码（用于配置生成文件）
#     REDIS_MODE            // 集群的架构（主从、哨兵、集群，用于生成的文件的命名）
#     REDIS_EXPORTER_PORT   // 启用的端口（用于 redis_exporter 端口的启用、生成的文件的命名）
#     NAMEESPACE            // 命名空间（用于配置 grafana 展示分组用的命名空间）
# 执行脚本将会进行以下操作:
#     1、创建目录用于存放配置文件
#     2、创建配置redis认证文件 （password-业务名-机房-模式-启用端口.json）
#     3、创建配置redis_exporter启动脚本 （exporter-业务名-机房-模式-启用端口.sh）
#     4、创建配置prometheus热加载文件 （fetch-业务名-机房-模式-启用端口.json）
# 执行成功后 prometheus.yml 需要手动配置并重启 prometheus

# 业务名
BUSINESS_SERVICE_NAME="test"
# 机房
ROOM_NAME_DATA_CENTER="bj"
# 当前redis架构各节点IP和端口
REDIS_LIST='
50.50.50.100:7000
50.50.50.101:7001
50.50.50.102:7002
50.50.50.103:7003
50.50.50.104:7004
50.50.50.105:7005
'
# redis认证密码
REDIS_PASSWORD=""
# redis集群的架构
REDIS_MODE="cluster"
# redis_exporter暴露的端口
REDIS_EXPORTER_PORT="9121"
# prometheus 命名空间
NAMEESPACE="测试-北京-分片集群-缓存-7000"


# 定义安装目录、配置文件目录、配置文件名称
# 安装目录
INSTALL_PATH="/usr/local/prometheus"
REDIS_EXPORTER_PATH="$INSTALL_PATH/redis_exporter-1.47.0"
PROMETHEUS_PATH="$INSTALL_PATH/prometheus-2.45.2"

# redis_exporter
# 脚本目录
SCRIPT_PATH="$REDIS_EXPORTER_PATH/conf/$BUSINESS_SERVICE_NAME/$ROOM_NAME_DATA_CENTER"
# 脚本名
SCRIPT_NAME="exporter-$BUSINESS_SERVICE_NAME-$ROOM_NAME_DATA_CENTER-$REDIS_MODE-$REDIS_EXPORTER_PORT"
# redis认证文件名
PASSWORD_NAME="password-$BUSINESS_SERVICE_NAME-$ROOM_NAME_DATA_CENTER-$REDIS_MODE-$REDIS_EXPORTER_PORT"
# 脚本文件
SCRIPT_FILE="$SCRIPT_PATH/${SCRIPT_NAME}.sh"
# redis认证文件
PASSWORD_FILE="$SCRIPT_PATH/${PASSWORD_NAME}.json"

# prometheus
# 热加载配置目录
PROMETHEUS_CONF_PATH="$PROMETHEUS_PATH/conf/conf.d/$BUSINESS_SERVICE_NAME/$ROOM_NAME_DATA_CENTER"
# 热加载配置名
PROMETHEUS_CONF_NAME="fetch-$BUSINESS_SERVICE_NAME-$ROOM_NAME_DATA_CENTER-$REDIS_MODE-$REDIS_EXPORTER_PORT"
# 热加载配置文件
PROMETHEUS_CONF_FILE="$PROMETHEUS_CONF_PATH/${PROMETHEUS_CONF_NAME}.json"



# 检查
if [ ! -d "$INSTALL_PATH" ]; then
    echo "$INSTALL PATH directory does not exist"
    exit 1
else
    if [ ! -d "$PROMETHEUS_PATH" ]; then
        echo "$PROMETHEUS_PATH PATH directory does not exist"
        exit 1
    else
        if [ ! -d "$REDIS_EXPORTER_PATH" ]; then
            echo "$REDIS_EXPORTER_PATH PATH directory does not exist"
            exit 1
        fi
    fi
fi



# 生成 redis_exporter 启动脚本
# 创建脚本存放目录
if [ ! -d "$SCRIPT_PATH" ];then
    mkdir -p $SCRIPT_PATH
fi

# 写入redis认证配置框架
cat > $PASSWORD_FILE << EOF
{
}
EOF
# 获取列表redis实例、redis密码写入认证配置
for IP_PORT in $REDIS_LIST
do
    sed -i "1a\\
    \"redis://$IP_PORT\": \"$REDIS_PASSWORD\"," $PASSWORD_FILE
done
sed -i 'x; ${s/,$//;p;x}; 1d' $PASSWORD_FILE

# 获取redis列表中的第一个实例作为建立连接的目标redis
REDIS_ADDR=$(echo $REDIS_LIST | awk '{print $1}')
# 获取变量配置启动脚本
cat > $SCRIPT_FILE << EOF
#!/bin/bash

nohup $REDIS_EXPORTER_PATH/redis_exporter \\
 -redis.addr $REDIS_ADDR \\
 -redis.password-file ${PASSWORD_NAME}.json \\
 -web.listen-address :$REDIS_EXPORTER_PORT \\
 > $REDIS_EXPORTER_PATH/logs/${SCRIPT_NAME}.out &
EOF
chmod +x $SCRIPT_FILE



# 生成 prometheus 热加载抓取配置
# 创建热加载配置存放目录
if [ ! -d "$PROMETHEUS_CONF_PATH" ];then
    mkdir -p $PROMETHEUS_CONF_PATH
fi

# 写入热加载配置框架
cat > $PROMETHEUS_CONF_FILE << EOF
[
  {
    "targets": [
    "labels": {"namespace": "$NAMEESPACE"}
  }
]
EOF
# 获取列表redis实例写入抓取配置
i=3
for IP_PORT in $REDIS_LIST
do
    sed -i "${i}s|$| \"redis://$IP_PORT\",|" $PROMETHEUS_CONF_FILE
    sed -i "${i}a\                " $PROMETHEUS_CONF_FILE
    ((i++))
done
total_lines=$(wc -l < $PROMETHEUS_CONF_FILE)
line_to_delete=$((total_lines - 3))
sed -i "${line_to_delete}d" $PROMETHEUS_CONF_FILE
line_to_replace=$((line_to_delete - 1))
sed -i "${line_to_replace}s:,$: ],:g" $PROMETHEUS_CONF_FILE
