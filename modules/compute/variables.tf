variable "nat_ami" {
  description = "NAT インスタンスのAMI ID"
  type        = string
}

variable "public_subnet_id" {
  description = "パブリックサブネットのID"
  type        = string
}

variable "nat_security_group_id" {
  description = "NAT インスタンスのセキュリティグループID"
  type        = string
}

variable "key_name" {
  description = "Name of the key pair"
  type        = string
}

variable "windows_ami" {
  description = "Windows Server のAMI ID"
  type        = string
}

variable "private_subnet_id" {
  description = "プライベートサブネットのID"
  type        = string
}

variable "windows_security_group_id" {
  description = "Windows ADサーバーのセキュリティグループID"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAMインスタンスプロファイル名"
  type        = string
}

variable "install_adds" {
  description = "Active Directory Domain Servicesをインストールするかどうか"
  type        = bool
}

variable "domain_name" {
  description = "Active Directoryドメイン名"
  type        = string
}

variable "domain_netbios_name" {
  description = "Active DirectoryのNetBIOS名"
  type        = string
}

variable "domain_admin_password" {
  description = "ドメイン管理者のパスワード"
  type        = string
  sensitive   = true
}

variable "windows_ad_private_ip" {
  description = "Fixed private IP for Windows AD server"
  type        = string
}

variable "windows_entra_private_ip" {
  description = "Fixed private IP for Windows Entra Connect server"
  type        = string
} 