variable "aws_region" {
  default = "ap-northeast-1"
}

variable "windows_2019_ami" {
  description = "Windows Server 2019 日本語版の AMI ID"
  default     = "ami-033b26e504cfde89c" # 最新の日本語版 AMI を取得して設定
}

variable "key_name" {
  description = "EC2 にアクセスするための SSH キーペア"
  default     = "windows_ad_key"
}

variable "availability_zone" {
  description = "EC2 インスタンスを起動するアベイラビリティゾーン"
  default     = "ap-northeast-1a"
}

variable "spot_price" {
  description = "スポットインスタンスの最大価格"
  default     = "0.0357"
}

variable "my_ip" {
  description = "RDP 接続を許可する IP アドレス (MY IP)"
  default     = "0.0.0.0/0" # デフォルトは全許可だが、適用時に変更
}

variable "enable_internet_gateway" {
  description = "インターネットゲートウェイを有効にするか"
  default     = true
}

variable "domain_name" {
  description = "Active Directory ドメイン名"
  type        = string
  default     = "kikudai.work"
}

variable "domain_netbios_name" {
  description = "Active Directory NetBIOS名"
  type        = string
  default     = "KIKUDAI"
}

variable "domain_admin_password" {
  description = "Active Directory 管理者パスワード"
  type        = string
  sensitive   = true
}

variable "install_adds" {
  description = "Active Directory Domain Servicesをインストールするかどうか"
  type        = bool
  default     = true
}
