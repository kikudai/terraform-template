# AWS Windows AD Template

## VPN証明書の生成

VPN接続に必要な証明書は、以下スクリプトを実行して作成する。

* 証明書生成スクリプトを実行
```bash
rm -rf ./vpn-certs
./generate-vpn-certs.sh
```


* 生成された証明書は`vpn-certs`ディレクトリに保存されます
   - `ca.crt`: CA証明書
   - `ca.key`: CA秘密鍵
   - `server.crt`: サーバー証明書
   - `server.key`: サーバー秘密鍵
   - `client.crt`: クライアント証明書
   - `client.key`: クライアント秘密鍵

**注意**: 証明書ファイル（特に`.key`ファイル）は安全に保管し、決してGitリポジトリにコミットしないでください。

## VPN接続手順

### 1. 事前準備

1. AWS VPNクライアントのインストール
   - [AWS公式サイト](https://aws.amazon.com/vpn/client-vpn-download/)からダウンロード
   - または Microsoft Store で "AWS VPN Client" を検索してインストール

2. クライアント設定ファイルの準備
   - Terraform実行後、自動的に`client-vpn-config.ovpn`が生成されます

### 2. VPN接続

1. AWS VPNクライアントの起動
   - スタートメニューから "AWS VPN Client" を起動

2. 設定ファイルのインポート
   - [プロファイルのインポート]をクリック
   - 生成された`client-vpn-config.ovpn`を選択

3. VPN接続の開始
   - インポートしたプロファイルを選択
   - [接続]をクリック

4. 接続の確認
   - 接続が成功すると、クライアントの状態が「接続済み」と表示

### 3. Windows ADサーバーへの接続

1. VPN接続を確立

2. パスワードの取得
```bash
# terraform 実行完了後、 instace-id が記載された
# 以下コマンドが表示されるのでコピペ実行
aws ec2 get-password-data --instance-id <インスタンスID> --priv-launch-key windows_ad_key.pem
```

3. RDP接続
   - ユーザー名: Administrator
   - パスワード: 上記コマンドで取得したパスワード
   - 接続先: インスタンスのプライベートIP

### 4. トラブルシューティング

1. 接続エラーの場合
   - VPN接続が確立していることを確認
   - セキュリティグループの設定を確認
   - 証明書が正しく生成されているか確認

2. 認証エラーの場合
   - 証明書が正しくインポートされているか確認
   - クライアント設定ファイル内の証明書パスが正しいか確認

3. RDP接続ができない場合
   - VPN接続が確立していることを確認
   - プライベートIPアドレスを使用していることを確認
   - セキュリティグループでRDPポート(3389)が許可されているか確認 