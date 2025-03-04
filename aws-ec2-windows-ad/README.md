# AWS Windows Server AD 環境構築 (Terraform)

このプロジェクトは、Terraform を使用して AWS 上に Windows Server 2019 をスポットインスタンスで構築し、Active Directory を設定するためのスクリプトを提供します。

## 前提条件

- Terraform がインストールされていること (`terraform --version` で確認)
- AWS CLI がインストールされ、適切な権限のある AWS アカウントに認証されていること (`aws configure` で設定)
- SSH キーペアを作成済み (`your-key-pair`)

## 構成

```
/aws-windows-ad
├── main.tf             # AWS Provider、VPC、EC2 定義
├── key.tf              # キーペアの自動生成
├── variables.tf        # 変数定義 (IGW 有無の切り替え追加)
├── outputs.tf          # 出力値定義
├── security_group.tf   # セキュリティグループ設定
├── iam.tf              # IAM ロール設定
├── network.tf          # ✅ 新規追加: IGW & ルートテーブル設定
├── userdata.ps1        # Windows Server の初期設定 (AD のセットアップ)
├── README.md           # 手順説明
```

## 使用方法

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

取得した AMI ID を `variables.tf` の `windows_2019_ami` に設定してください。

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
  -var="my_ip=$(curl -s https://checkip.amazonaws.com)/32"
```

### 4. インフラの適用

デフォルトのスポット価格 (`0.040200`) と AZ (`ap-northeast-1d`) を使用:

```bash
terraform apply -auto-approve
```

特定のスポット価格や AZ を指定して適用:

```bash
terraform apply \
  -var="my_ip=$(curl -s https://checkip.amazonaws.com)/32" \
  -auto-approve
```

**成功すると、スポットインスタンスの EC2 上に Windows Server 2019 が作成され、AD ドメイン (`example.local`) が設定されます。**

### 4. Windows Server への接続

Terraform の出力にある `windows_ad_public_ip` を使用し、リモートデスクトップで接続します。
IDは Administrator で、パスワードは、以下AWS CLIで取得できます。

```bash
aws ec2 get-password-data --instance-id <インスタンスID> --priv-launch-key windows_ad_key.pem
```

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
