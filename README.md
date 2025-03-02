# AWS Windows AD Template

## VPN証明書の生成

VPN接続に必要な証明書は、セキュリティ上の理由からGitリポジトリには含まれていません。
以下の手順で証明書を生成してください：

1. `aws-ec2-windows-ad`ディレクトリに移動
```bash
cd aws-ec2-windows-ad
```

2. 証明書生成スクリプトを実行
```bash
./generate-vpn-certs.sh
```

3. 生成された証明書は`vpn-certs`ディレクトリに保存されます
   - `ca.crt`: CA証明書
   - `server.crt`: サーバー証明書
   - `client.crt`: クライアント証明書
   - `client-config.ovpn`: OpenVPNクライアント設定ファイル

**注意**: 証明書ファイル（特に`.key`ファイル）は安全に保管し、決してGitリポジトリにコミットしないでください。 