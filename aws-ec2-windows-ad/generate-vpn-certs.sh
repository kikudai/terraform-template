#!/bin/bash

# easy-rsaのバージョン
EASY_RSA_VERSION="3.2.2"

# ドメイン設定
DOMAIN="kikudai.work"

# 作業ディレクトリの作成
rm -rf vpn-certs
mkdir -p vpn-certs
cd vpn-certs

# easy-rsaのダウンロードと展開
curl -L https://github.com/OpenVPN/easy-rsa/releases/download/v${EASY_RSA_VERSION}/EasyRSA-${EASY_RSA_VERSION}.tgz | tar xz
cd EasyRSA-${EASY_RSA_VERSION}

# varsファイルの設定
# 証明書の有効期間を3650日に設定
cat > vars << EOF
set_var EASYRSA_CERT_EXPIRE    3650
EOF

# PKIの初期化
./easyrsa init-pki

# CA証明書の生成
echo "CA証明書の生成中..."
./easyrsa --batch build-ca nopass

# サーバー証明書の生成
echo "サーバー証明書の生成中..."
./easyrsa --batch build-server-full ${DOMAIN} nopass

# クライアント証明書の生成
echo "クライアント証明書の生成中..."
./easyrsa --batch build-client-full client nopass

# 証明書のコピー
cp pki/ca.crt ../ca.crt
cp pki/private/ca.key ../ca.key
cp pki/issued/${DOMAIN}.crt ../server.crt
cp pki/private/${DOMAIN}.key ../server.key
cp pki/issued/client.crt ../client.crt
cp pki/private/client.key ../client.key

# クリーンアップ
cd ..
rm -rf EasyRSA-${EASY_RSA_VERSION}

echo "証明書の生成が完了しました。"
echo "生成されたファイル:"
echo "- ca.crt: CA証明書"
echo "- ca.key: CA秘密鍵"
echo "- server.crt: サーバー証明書"
echo "- server.key: サーバー秘密鍵"
echo "- client.crt: クライアント証明書"
echo "- client.key: クライアント秘密鍵"