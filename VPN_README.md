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
rm -rf ./vpn-certs
./generate-vpn-certs.sh
```

3. 生成された証明書は`vpn-certs`ディレクトリに保存されます
   - `ca.crt`: CA証明書
   - `server.crt`: サーバー証明書
   - `client.crt`: クライアント証明書
   - `client-config.ovpn`: OpenVPNクライアント設定ファイル

**注意**: 証明書ファイル（特に`.key`ファイル）は安全に保管し、決してGitリポジトリにコミットしないでください。

## VPN接続手順

### 1. 事前準備

1. AWS VPNクライアントのインストール
   - [AWS公式サイト](https://aws.amazon.com/vpn/client-vpn-download/)からダウンロード
   - または Microsoft Store で "AWS VPN Client" を検索してインストール

2. クライアント設定ファイルの準備
   
   方法1: AWS CLIを使用
   ```bash
   # AWS CLIで設定ファイルをダウンロード
   aws ec2 export-client-vpn-client-configuration \
       --client-vpn-endpoint-id cvpn-endpoint-0e08703f2e739722f \
       --region ap-northeast-1 \
       --output text > aws-vpn-config.ovpn
   ```

   方法2: AWSマネジメントコンソールを使用
   1. [AWSマネジメントコンソール](https://console.aws.amazon.com/)にログイン
   2. 検索バーで「VPC」と入力し、VPCダッシュボードを開く
   3. 左側のメニューから「Client VPN エンドポイント」を選択
   4. 対象のClient VPNエンドポイントを選択
   5. 「クライアント設定」タブをクリック
   6. 「クライアント設定のダウンロード」ボタンをクリック
   7. ダウンロードした設定ファイル（.ovpn）を保存

   方法3: 設定ファイルの統合（推奨）
   1. AWSマネジメントコンソールから設定ファイルをダウンロード
   2. `generate-vpn-certs.sh`で生成した証明書ファイルを開く
   3. ダウンロードした設定ファイルに、生成した証明書の<cert>と<key>セクションを追加
   4. 統合した設定ファイルを新しい名前で保存（例：`combined-config.ovpn`）

   **注意**: 証明書セクション（<ca>, <cert>, <key>）の順序は維持してください。

### 2. VPN接続

1. AWS VPNクライアントの起動
   - スタートメニューから "AWS VPN Client" を起動

2. 設定ファイルのインポート
   - [プロファイルのインポート]をクリック
   - ダウンロードした`aws-vpn-config.ovpn`を選択

3. VPN接続の開始
   - インポートしたプロファイルを選択
   - [接続]をクリック

4. 接続の確認
   - 接続が成功すると、クライアントの状態が「接続済み」と表示
   - 以下のコマンドでVPN経由の接続を確認：
     ```bash
     ping 10.0.1.126  # Active DirectoryサーバーのプライベートIP
     ```

### 3. トラブルシューティング

1. 接続エラーの場合
   - クライアント設定ファイルのDNS名が正しいか確認
   - セキュリティグループの設定を確認（UDP 443ポートが開いているか）
   - 証明書が正しく生成されているか確認

2. 認証エラーの場合
   - 証明書が正しくインポートされているか確認
   - クライアント設定ファイル内の証明書パスが正しいか確認

3. ルーティングの問題
   - VPNクライアントのログを確認
   - AWS VPCのルートテーブル設定を確認

4. DNS解決エラー（Cannot resolve host address）の場合
   - AWS CLIで正しいエンドポイントDNS名を取得
     ```bash
     aws ec2 describe-client-vpn-endpoints --query 'ClientVpnEndpoints[*].DnsName' --output text
     ```
   - `client-config.ovpn`ファイル内の`remote`行を確認し、以下の形式になっているか確認
     ```
     remote エンドポイントDNS名 443 udp
     ```
   - ホストPCのDNS設定を確認
     - Windows: `ipconfig /all`でDNSサーバーの設定を確認
     - 以下の手順でGoogle Public DNSを追加：
       ```powershell
       # 管理者としてPowerShellを開き実行
       netsh interface ip add dns "Wi-Fi" 8.8.8.8 index=2
       ipconfig /flushdns
       ```
     - DNSの変更後、OpenVPNクライアントを再起動して接続を試みる
   - `C:\Windows\System32\drivers\etc\hosts`ファイルに競合する設定がないか確認
   - 上記の設定を行っても解決しない場合：
     - ネットワークアダプターの設定を開く
     - Wi-Fiアダプターのプロパティ → IPv4 → プロパティ
     - DNSサーバーを手動設定：
       - 優先DNSサーバー: 8.8.8.8
       - 代替DNSサーバー: 8.8.4.4 