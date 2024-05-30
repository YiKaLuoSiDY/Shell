#!/bin/bash

# 停止应用
ps uax | grep -E '[p]rometheus|[r]edis_exporter|[n]ode_exporter|[g]rafana' | awk '{print $2}' | xargs -r kill -9

# 卸载应用
cd /usr/local
rm -rf ./prometheus
rpm -qa | grep grafana | xargs -r yum remove -y

# 删除残留
cd /usr/lib/systemd/system/
rm -f ./grafana*
rm -f ./prometheus*
rm -f ./node_exporter*
cd /etc/
rm -rf ./grafana
