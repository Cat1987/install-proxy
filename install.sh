#!/bin/bash

model=$1

if [ ! $1 ]; then
  echo "[ERROR] You must specify which software you want to install. Eg: ./install s/ns (s -> ShadowSocks ns -> Nginx
  +ShadowSocks)"
  exit
fi

# Parameter Validation
if [ $model = "s" ]; then
  echo "Install model is: Install ShadowSocks only :)"
elif [ $model = "ns" ]; then
  echo "Install model is: Install Nginx and ShadowSocks :)"
else
  echo "[ERROR] Invalid parameter, choose the correct value. 's' or 'ns' "
    exit
fi

# Tip for making sure in the right OS
echo "Make sure you are using Centos7! The process of installation is for Centos7"

# Optimize the kernel parameters
echo "Optimize the kernel parameters..."

echo "Add nofile 65536 to /etc/security/limits.conf"
if [ `ulimit -n` -lt 65536 ]; then
    {
    echo "* soft nofile 65536"
    echo "* hard nofile 65536"
    } >> /etc/security/limits.conf
fi

echo "Configure kernel parameters for ShadowSocks. Add parameters to /etc/sysctl.conf"
{
echo "fs.file-max = 51200"
echo "net.core.rmem_max = 67108864"
echo "net.core.wmem_max = 67108864"
echo "net.core.netdev_max_backlog = 250000"
echo "net.core.somaxconn = 4096"
echo "net.ipv4.tcp_syncookies = 1"
echo "net.ipv4.tcp_tw_reuse = 1"
echo "net.ipv4.tcp_tw_recycle = 0"
echo "net.ipv4.tcp_fin_timeout = 30"
echo "net.ipv4.tcp_keepalive_time = 1200"
echo "net.ipv4.ip_local_port_range = 1024 65000"
echo "net.ipv4.tcp_max_syn_backlog = 8192"
echo "net.ipv4.tcp_max_tw_buckets = 5000"
echo "net.ipv4.tcp_fastopen = 3"
echo "net.ipv4.tcp_mem = 25600 51200 102400"
echo "net.ipv4.tcp_rmem = 4096 87380 67108864"
echo "net.ipv4.tcp_wmem = 4096 65536 67108864"
echo "net.ipv4.tcp_mtu_probing = 1"
echo "net.ipv4.tcp_congestion_control = hybla"
} >> /etc/sysctl.conf

sysctl -p

# Install necessary tool
yum install -y net-tools
yum install -y python3-pip
yum install -y libsodium

# Get Local private IP
echo "Get local private IP"
localIP=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
echo "Local private IP is $localIP "
sw_json_conf='{"server":'+ $localIP + ',"local_address":"127.0.0.1","local_port":1080,"port_password":{"8388":"520Xyx0123",
"8389":"520Xyx0123","8390":"do_not_share_the_password","8391":"520Xyx0123"},"timeout":300,"method":"aes-256-gcm","fast_open":false}'

if [ $model = "s" ]; then
  echo "Now Install ShadowSocks :)"
  pip3 install -y https://github.com/shadowsocks/shadowsocks/archive/master.zip
  ssserver --version
  echo "$sw_json_conf" > /etc/shadowsocks.json

  {
    echo "[Unit]"
    echo "Description=Shadowsocks Server"
    echo "After=network.target"
    echo "[Service]"
    echo "ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks.json"
    echo "Restart=on-abort"
    echo "[Install]"
    echo "WantedBy=multi-user.target"
  } >> /etc/systemd/system/shadowsocks-server.service
  systemctl start shadowsocks-server
  systemctl enable shadowsocks-server

elif [ $model = "ns" ]; then
  echo "Install model is: Install Nginx and ShadowSocks :)"
else
  echo "[ERROR] Invalid parameter, choose the correct value. 's' or 'ns' "
    exit
fi
