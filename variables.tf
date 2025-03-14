variable "aws_region" {
  default = "ap-northeast-1"
}

variable "windows_ami" {
  description = "Windows Server 2016 日本語版の AMI ID"
  default     = "ami-05664ae0ae93d4f43"
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
  default     = "example.local"
}

variable "domain_netbios_name" {
  description = "Active Directory NetBIOS名"
  type        = string
  default     = "EXAMPLE"
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

variable "nat_ami" {
  description = "AMI ID for NAT Instance (Amazon Linux 2023 ARM64)"
  type        = string
  default     = "ami-0a9e614c3d1eaa27d"
}

variable "vpc_cidr" {
  description = "VPC のメイン CIDR ブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "サブネットの CIDR ブロックのリスト"
  type        = map(string)
  default     = {
    public_1a  = "10.0.1.0/24"
    public_1c  = "10.0.2.0/24"
    private_1a = "10.0.10.0/24"
  }
}

variable "vpn_client_cidr" {
  description = "VPN クライアント用の CIDR ブロック"
  type        = string
  default     = "10.17.0.0/22"
} 
