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
$(cat ./vpn-certs/ca.crt)
</ca>

# クライアント証明書（client.crt）
<cert>
$(cat ./vpn-certs/client.crt)
</cert>

# クライアント秘密鍵（client.key）
<key>
$(cat ./vpn-certs/client.key)
</key>
EOF
