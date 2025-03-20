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

variable "userdata_template_path" {
  description = "User dataテンプレートファイルのパス"
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