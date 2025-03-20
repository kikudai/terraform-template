#!/bin/bash
set -e  # エラーが発生したら即座に終了

# 関数定義
handle_error() {
    echo "Error occurred at line $1" >> /var/log/user-data.log
    exit 1
}

trap 'handle_error $LINENO' ERR

# スクリプトの実行ユーザーを確認（デバッグ用）
echo "Script running as user: $(whoami)" >> /var/log/user-data.log

# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Install and configure iptables-services
yum install -y iptables-services

# ネットワークインターフェースの準備を待つ
while ! ip link show ens5 up; do
    echo "Waiting for ens5 interface..."
    sleep 2
done

# Configure NAT
echo "Configure NAT" | tee -a /var/log/user-data.log
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE | tee -a /var/log/user-data.log
iptables -t nat -L -v --line-numbers | tee -a /var/log/user-data.log 

service iptables save
systemctl enable iptables

# 実行結果のログ
echo "Setup script completed at $(date)" >> /var/log/user-data.log 