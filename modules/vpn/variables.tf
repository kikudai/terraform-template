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

variable "security_group_ids" {
  description = "VPNエンドポイントに適用するセキュリティグループID"
  type        = list(string)
}

variable "dns_servers" {
  description = "Windows ADのプライベートIP"
  type        = list(string)
}

variable "subnet_id_1" {
  description = "VPN接続用のサブネットID 1"
  type        = string
}

variable "subnet_id_2" {
  description = "VPN接続用のサブネットID 2"
  type        = string
}

variable "target_network_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
} 