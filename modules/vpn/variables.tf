variable "domain_name" {
  description = "ドメイン名"
  type        = string
}

variable "vpn_client_cidr" {
  description = "VPNクライアントのCIDRブロック"
  type        = string
}

variable "vpc_id" {
  description = "VPCのID"
  type        = string
}

variable "security_group_id" {
  description = "VPNエンドポイントに適用するセキュリティグループID"
  type        = string
}

variable "windows_ad_private_ip" {
  description = "Windows ADのプライベートIP"
  type        = string
}

variable "subnet_id_1" {
  description = "VPN接続用のサブネットID 1"
  type        = string
}

variable "subnet_id_2" {
  description = "VPN接続用のサブネットID 2"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
} 