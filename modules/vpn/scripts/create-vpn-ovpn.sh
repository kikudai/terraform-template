#!/bin/bash

# スクリプトの場所を取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# VPN証明書のディレクトリパスを設定
CERT_DIR="${SCRIPT_DIR}/../vpn-certs"

# ドメイン設定
VPN_ENDPOINT_DNS=$(aws ec2 describe-client-vpn-endpoints --query 'ClientVpnEndpoints[0].DnsName' --output text | sed 's/^\*\.//')

# クライアント設定ファイルの生成
cat > client-vpn-config.ovpn << EOF
client
dev tun
proto tcp
remote ${VPN_ENDPOINT_DNS} 443
remote-random-hostname
resolv-retry infinite
nobind
remote-cert-tls server
cipher AES-256-GCM
verb 3

# CA証明書（ca.crt）
<ca>
$(cat "${CERT_DIR}/ca.crt")
</ca>

# クライアント証明書（client.crt）
<cert>
$(cat "${CERT_DIR}/client.crt")
</cert>

# クライアント秘密鍵（client.key）
<key>
$(cat "${CERT_DIR}/client.key")
</key>
EOF
