#!/bin/bash

# 必要なディレクトリを作成
mkdir -p vpn-certs
cd vpn-certs

# 設定
DOMAIN="kikudai.work"

# CA証明書の設定ファイル
cat > ca.ext << EOF
basicConstraints = critical,CA:TRUE
keyUsage = critical,digitalSignature,keyEncipherment,keyCertSign,cRLSign,dataEncipherment
extendedKeyUsage = serverAuth,clientAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

# CA証明書の生成
openssl req -x509 -new -nodes -days 3650 -newkey rsa:2048 \
    -keyout ca.key -out ca.crt \
    -subj "/CN=${DOMAIN}/O=Windows AD VPN CA" \
    -config <(cat /etc/ssl/openssl.cnf \
        <(printf "\n[v3_ca]\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid:always,issuer\nbasicConstraints=critical,CA:TRUE\nkeyUsage=critical,digitalSignature,keyEncipherment,keyCertSign,cRLSign,dataEncipherment\nextendedKeyUsage=serverAuth,clientAuth"))

# サーバー証明書の生成
openssl req -new -newkey rsa:2048 -nodes \
    -keyout server.key -out server.csr \
    -subj "/CN=${DOMAIN}/O=Windows AD VPN Server"

# サーバー証明書の設定ファイル
cat > server.ext << EOF
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment,dataEncipherment
extendedKeyUsage = serverAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
subjectAltName = DNS:${DOMAIN}
EOF

# サーバー証明書の署名
openssl x509 -req -days 3650 -in server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out server.crt -extfile server.ext

# クライアント証明書の生成
openssl req -new -newkey rsa:2048 -nodes \
    -keyout client.key -out client.csr \
    -subj "/CN=client.${DOMAIN}/O=Windows AD VPN Client"

# クライアント証明書の設定ファイル
cat > client.ext << EOF
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment,dataEncipherment
extendedKeyUsage = clientAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
EOF

# クライアント証明書の署名
openssl x509 -req -days 3650 -in client.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out client.crt -extfile client.ext

# クライアント設定ファイルの生成
cat > client-config.ovpn << EOF
client
dev tun
proto udp
remote YOUR_VPN_ENDPOINT_DNS 443
remote-random-hostname
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
verb 3
<ca>
$(cat ca.crt)
</ca>
<cert>
$(cat client.crt)
</cert>
<key>
$(cat client.key)
</key>
EOF

# 権限の設定
chmod 600 *.key
chmod 644 *.crt *.csr *.ovpn *.ext 