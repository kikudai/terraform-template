# AWS Windows Server AD 環境構築 (Terraform)

このプロジェクトは、Terraform を使用して AWS 上に Windows Server 2019 をスポットインスタンスで構築し、Active Directory を設定するためのスクリプトを提供します。

## 前提条件

- Terraform がインストールされていること (`terraform --version` で確認)
- AWS CLI がインストールされ、適切な権限のある AWS アカウントに認証されていること (`aws configure` で設定)

## 構成

```
/aws-windows-ad
├── main.tf             # AWS Provider、VPC、EC2 定義
├── key.tf              # キーペアの自動生成
├── variables.tf        # 変数定義 (IGW 有無の切り替え追加)
├── outputs.tf          # 出力値定義
├── security_group.tf   # セキュリティグループ設定
├── iam.tf              # IAM ロール設定
├── network.tf          # 新規追加: IGW & ルートテーブル設定
├── userdata.ps1        # Windows Server の初期設定 (AD のセットアップ)
├── README.md           # 手順説明
```

## 使用方法

### 0. 証明書生成スクリプトを実行
```bash
rm -rf ./vpn-certs
./generate-vpn-certs.sh
```

### 1. Terraform の初期化

```sh
terraform init
```

### 2. Windows Server 2019 日本語版の AMI 確認

AWS CLI を使用して、東京リージョン (`ap-northeast-1`) の **最新の Windows Server 2019 日本語版 AMI** を取得できます。

```sh
aws ec2 describe-images \
  --owners "amazon" \
  --filters "Name=name,Values=Windows_Server-2019-Japanese-Full-Base-*" \
  --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
  --region ap-northeast-1
```

取得した AMI ID を `variables.tf` の `windows_ami` に設定してください。

### 3. スポットインスタンスの価格確認

AWS CLI を使用して、東京リージョン (`ap-northeast-1`) の `t3.medium` の最新スポット価格を確認できます。

```sh
aws ec2 describe-spot-price-history \
  --instance-types t3.medium \
  --product-descriptions "Windows" \
  --start-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --region ap-northeast-1 \
  --query 'SpotPriceHistory[0].SpotPrice'
```

### 3. RDP 接続用に自分の IP を取得

Terraform 実行前に、自分のグローバル IP アドレスを取得し、環境変数として設定します。

```sh
echo $(curl -s https://checkip.amazonaws.com)/32
```

これにより、自分のグローバル IP のみを RDP 接続許可対象にできます。

### 4. Terraform Plan で変更内容を確認

```bash
terraform plan \
  -var="my_ip=$(curl -s https://checkip.amazonaws.com)/32" \
  -var="domain_name=example.com" \
  -var="domain_netbios_name=EXAMPLE"
```

### 4. インフラの適用

```bash
terraform apply \
  -var="my_ip=$(curl -s https://checkip.amazonaws.com)/32" \
  -var="domain_name=example.com" \
  -var="domain_netbios_name=EXAMPLE" \
  -auto-approve
```

実行後、以下のリソースが作成されます：
- Windows Server 2019 EC2インスタンス（Active Directory）
- Client VPN エンドポイント
- 必要な証明書（自動生成）
- OpenVPN設定ファイル

### 5. VPN接続の設定

1. Terraform実行完了後、カレントディレクトリに `client-vpn-config.ovpn` が生成されます
2. この設定ファイルをOpenVPNクライアントにインポートします
3. VPN接続を開始し、プライベートサブネットにアクセスできることを確認します

### 6. Windows Server への接続

Terraform の出力にある `windows_ad_public_ip` を使用し、リモートデスクトップで接続します。
IDは Administrator で、パスワードは、以下AWS CLIで取得できます。

```bash
aws ec2 get-password-data --instance-id <インスタンスID> --priv-launch-key windows_ad_key.pem
```

## クリーンアップ

作成したリソースを削除する場合:

```sh
terraform destroy -auto-approve
```

## AWS構成図

```mermaid
---
title: AWS VPN with Active Directory 構成図
---
flowchart TB
    Client[クライアント<br>VPNクライアントツール]

    subgraph AWS[AWS Cloud]
        subgraph VPC[VPC]
            subgraph Private[プライベートサブネット]
                AD[Windows ADサーバー<br>sg: windows_ad]
            end

            subgraph Public[パブリックサブネット]
                VPNEndpoint[Client VPNエンドポイント<br>sg: vpn_endpoint]
            end
        end
    end

    Client -->|"1.VPN接続開始<br>443(tcp/udp)<br>from: var.my_ip"| VPNEndpoint
    Client -->|"2.VPN接続確立後<br>3389(tcp), AD関連通信<br>from: var.vpn_client_cidr"| AD

    style AWS fill:#ff9900,stroke:#232f3e
    style VPC fill:#e8f6fe,stroke:#147eba
    style Public fill:#d6ffe8,stroke:#1b660f
    style Private fill:#ffe8e8,stroke:#ba1414
```

## 注意事項

- AWS のコストが発生するため、不要な場合は `terraform destroy` で削除してください。
- `userdata.ps1` の `YourSecurePassword!` は適切なものに変更してください。
- VPN証明書は自動生成されますが、運用環境では適切な証明書管理が必要です。
- Client VPN エンドポイントには別途料金が発生します。

## ライセンス

MIT
