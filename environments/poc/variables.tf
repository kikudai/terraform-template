variable "key_name" {
  description = "EC2 にアクセスするための SSH キーペア"
  type        = string
  default     = "windows_ad_key"
}

variable "environment" {
  description = "環境名"
  type        = string
  default     = "poc"
}

variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "my_ip" {
  description = "許可するIPアドレス"
  type        = string
}

variable "domain_name" {
  description = "ドメイン名"
  type        = string
}

variable "domain_netbios_name" {
  description = "NetBIOS名"
  type        = string
}

variable "domain_admin_password" {
  description = "ドメイン管理者のパスワード"
  type        = string
  sensitive   = true  // パスワードは機密情報として扱う
}

variable "additional_tags" {
  description = "追加のタグ"
  type        = map(string)
  default     = {}
}

variable "public_key_path" {
  description = "SSHの公開鍵のパス"
  type        = string
  default     = "public_key.pub"
}

// 他の必要な変数定義
