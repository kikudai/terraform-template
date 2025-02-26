# AWS Windows Server AD 環境構築 (Terraform)

このプロジェクトは、Terraform を使用して AWS 上に Windows Server 2019 をスポットインスタンスで構築し、Active Directory を設定するためのスクリプトを提供します。

## 前提条件

- Terraform がインストールされていること (`terraform --version` で確認)
- AWS CLI がインストールされ、適切な権限のある AWS アカウントに認証されていること (`aws configure` で設定)
- SSH キーペアを作成済み (`your-key-pair`)

## 構成

```
/terraform-windows-ad
├── main.tf             # AWS Provider、VPC、EC2 定義
├── key.tf              # キーペアの自動生成
├── variables.tf        # 変数定義
├── outputs.tf          # 出力値定義
├── security_group.tf   # セキュリティグループ設定
├── iam.tf              # IAM ロール設定
├── userdata.ps1        # Windows Server の初期設定 (AD のセットアップ)
├── README.md           # 手順説明
```

## 使用方法

### 1. Terraform の初期化

```sh
terraform init
```

### 2. スポットインスタンスの価格確認

AWS CLI を使用して、東京リージョン (`ap-northeast-1`) の `t3.medium` の最新スポット価格を確認できます。

```sh
aws ec2 describe-spot-price-history \
  --instance-types t3.medium \
  --product-descriptions "Windows" \
  --start-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --region ap-northeast-1 \
  --query 'SpotPriceHistory[0].SpotPrice'
```

### 3. インフラの適用

デフォルトのスポット価格 (`0.0357`) と AZ (`ap-northeast-1d`) を使用:

```sh
terraform apply -auto-approve
```

特定のスポット価格や AZ を指定して適用:

```sh
terraform apply -var="spot_price=0.0366" -var="availability_zone=ap-northeast-1c" -auto-approve
```

**成功すると、スポットインスタンスの EC2 上に Windows Server 2019 が作成され、AD ドメイン (`example.local`) が設定されます。**

### 4. Windows Server への接続

Terraform の出力にある `windows_ad_public_ip` を使用し、RDP で接続します。

### 5. ローカル PC をドメインに参加

1. **ローカル Windows の DNS を変更**

   - `example.local` の DNS に、Terraform で作成した EC2 の **プライベート IP** を設定。

2. **PowerShell でドメイン参加**
   ```powershell
   Add-Computer -DomainName "example.local" -Credential "example\Administrator" -Restart
   ```

## クリーンアップ

作成したリソースを削除する場合:

```sh
terraform destroy -auto-approve
```

## 注意事項

- AWS のコストが発生するため、不要な場合は `terraform destroy` で削除してください。
- `userdata.ps1` の `YourSecurePassword!` は適切なものに変更してください。
- スポット価格と AZ を変数 (`spot_price`, `availability_zone`) で管理しているため、Terraform 実行時に指定できます。

## ライセンス

MIT
