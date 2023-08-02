#!/bin/bash

if [ ! "$1" ]; then
    echo "[ERROR] You must specify which ips you want to load balance.
    Please use the field separator ',' EG: ./install ip1:port1,ip2:port2,ip3:port3"
    exit
  fi

ipList=$1

# Centos7 Command
InstallNginx(){
  yum update
  sudo rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
  yum install nginx -y
  service nginx start
  systemctl enable nginx.service
}

# This function must been after InstallNginx
ConfigureLoadBalance(){
  mkdir -p /etc/nginx/tcpconf.d
  echo "stream {
        upstream group1 {
            }
            server {
                listen 10000;
                listen 10000 udp;
                proxy_pass group1;
            }
        }" > /etc/nginx/tcpconf.d/ssrproxy.conf
  # Use comma as separator and apply as pattern
  for val in ${ipList//,/ }
  do
    echo "$val"
    sed -i "3i $val;" /etc/nginx/tcpconf.d/ssrproxy.conf
  done
  echo "include /etc/nginx/tcpconf.d/*.conf;" >> /etc/nginx/nginx.conf
}

OptimizeNginxConf(){
  sed -i "1i worker_rlimit_nofile 51200;" /etc/nginx/nginx.conf
  #update work connections
  sed -i "s/worker_connections  1024;/worker_connections  10240;/g" /etc/nginx/nginx.conf
  nginx -t
  nginx -s reload
}

InstallNginx
ConfigureLoadBalance
OptimizeNginxConf
