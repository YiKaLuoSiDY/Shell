The provided script (centos_prometheus_setup.sh) automates the installation and configuration of Prometheus, Node Exporter, Redis Exporter, and Grafana on a CentOS system. It includes handling for both CentOS 6 and CentOS 7, ensuring services are set up correctly for each version. Below is an explanation of each part of the script.

### Key Parts of the Script:

1. **Variables and Functions**:
   - `INSTALL_PATH`, `PROMETHEUS_PATH`, `REDIS_EXPORTER_PATH`, and `NODE_EXPORTER_PATH` are defined to specify the installation directories for Prometheus, Redis Exporter, and Node Exporter.
   - `failure` function prints a failure message and returns the exit status.
   - `if_failure` function checks if the previous command failed and exits the script if it did.

2. **CentOS 6 and 7 Service Configuration Functions**:
   - `centos6_start_service` downloads and configures the init scripts for CentOS 6.
   - `centos7_start_service` creates systemd service files for CentOS 7.

3. **Installation Directory and Grafana Check**:
   - Checks if the installation directory already exists and exits if it does.
   - Checks if Grafana is already installed and exits if it is.

4. **Downloading and Extracting Packages**:
   - Downloads the Prometheus, Node Exporter, Redis Exporter, and Grafana packages.
   - Extracts the downloaded tarballs and organizes the files into the appropriate directories.

5. **Installing and Enabling Services**:
   - Configures the services for either CentOS 6 or CentOS 7, enabling them to start on boot.
   - Adjusts the Grafana service configuration for CentOS 7 to ensure it doesn't restart automatically on failure.

6. **Cleanup**:
   - Removes the downloaded tarball files after the installation is complete.

### Detailed Explanation:

#### Variable Definitions:
```bash
INSTALL_PATH="/usr/local/prometheus"
PROMETHEUS_PATH="$INSTALL_PATH/prometheus-2.45.2"
REDIS_EXPORTER_PATH="$INSTALL_PATH/redis_exporter-1.47.0"
NODE_EXPORTER_PATH="$INSTALL_PATH/node_exporter-1.7.0"
```
These lines set up the installation directories for the applications.

#### Failure Handling Functions:
```bash
failure() {
    local rc=$?
    echo -en "\\033[60G[\\033[1;31mFAILED\\033[0;39m]\r"
    [ -x /bin/plymouth ] && /bin/plymouth --details
    return $rc
}

if_failure() {
    if [ $? -ne 0 ]; then
        echo
        failure
        exit 1
    fi
}
```
These functions handle failures by printing an error message and exiting the script.

#### CentOS 6 and 7 Service Configuration:
For CentOS 6:
```bash
centos6_start_service() {
    # 下载 prometheus 启动配置
    wget -P /etc/init.d/ https://raw.githubusercontent.com/YiKaLuoSiDY/cong/main/prometheus
    if_failure "prometheus 启动配置下载失败"
    sed -i "s/\$PROMETHEUS_PATH/$PROMETHEUS_PATH/g" /etc/init.d/prometheus

    # 下载 node_exporter 启动配置
    wget -P /etc/init.d/ https://raw.githubusercontent.com/YiKaLuoSiDY/cong/main/node_exporter || exit 1
    if_failure "node_exporter 启动配置下载失败"
    sed -i "s/\$NODE_EXPORTER_PATH/$NODE_EXPORTER_PATH/g" /etc/init.d/node_exporter

    # 添加执行权限
    chmod +x /etc/init.d/{prometheus,node_exporter}
}
```
For CentOS 7:
```bash
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
```
These functions set up the necessary service configurations for Prometheus and Node Exporter for CentOS 6 and CentOS 7.

#### Installation Check:
```bash
if [ -d "$INSTALL_PATH" ]; then
    echo "Installation directory "$INSTALL_PATH" exists, need to delete directory manually!"
    exit 1
else
    rpm -qa | grep grafana && {
        echo "grafana is already installed, so you'll need to uninstall it manually"
        exit 1
        }
fi
```
This block ensures the installation directory does not already exist and that Grafana is not already installed.

#### Download and Extraction:
```bash
cd /root
wget https://github.com/prometheus/prometheus/releases/download/v2.45.2/prometheus-2.45.2.linux-amd64.tar.gz
if_failure "prometheus-2.45.2.linux-amd64.tar.gz 下载失败"
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
if_failure "node_exporter-1.7.0.linux-amd64.tar.gz 下载失败"
wget https://github.com/oliver006/redis_exporter/releases/download/v1.47.0/redis_exporter-v1.47.0.linux-amd64.tar.gz
if_failure "redis_exporter-v1.47.0.linux-amd64.tar.gz 下载失败"
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-8.5.2-1.x86_64.rpm
if_failure "grafana-enterprise-8.5.2-1.x86_64.rpm 下载失败"
mkdir $INSTALL_PATH
```
This block downloads the necessary files and creates the installation directory.

#### Installation and Configuration:
```bash
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
```
This block extracts the downloaded tarballs and moves the files to their respective directories. It also installs Grafana using `yum`.

#### Enabling Services:
```bash
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
```
This block detects the CentOS version and sets up the services accordingly. It ensures that services are enabled to start on boot.

