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

variable "my_ip" {
  description = "RDP 接続を許可する IP アドレス (MY IP)"
  default     = "0.0.0.0/0" # デフォルトは全許可だが、適用時に変更
}

variable "domain_name" {
  description = "Active Directory ドメイン名"
  type        = string
  default     = "kikudai.local"
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

variable "vpn_client_cidr" {
  description = "The CIDR block for VPN clients"
  type        = string
  default     = "172.16.0.0/22"  # VPNクライアント用のCIDR
}
