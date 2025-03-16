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

variable "public_subnet_1c" {
  description = "First subnet ID for VPN association"
  type        = string
}

variable "private_subnet_1a" {
  description = "Second subnet ID for VPN association"
  type        = string
}

variable "target_network_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
} 