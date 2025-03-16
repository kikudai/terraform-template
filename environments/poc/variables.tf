variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type        = map(string)
}

variable "vpn_client_cidr" {
  description = "CIDR block for VPN clients"
  type        = string
}

variable "my_ip" {
  description = "Your IP address for VPN access"
  type        = string
}

variable "key_name" {
  description = "Name of the key pair"
  type        = string
}

variable "nat_ami" {
  description = "AMI ID for NAT instance"
  type        = string
}

variable "windows_ami" {
  description = "AMI ID for Windows instance"
  type        = string
}

variable "install_adds" {
  description = "Whether to install Active Directory Domain Services"
  type        = bool
}

variable "domain_name" {
  description = "Domain name for Active Directory"
  type        = string
}

variable "domain_netbios_name" {
  description = "NetBIOS name for Active Directory domain"
  type        = string
}

variable "domain_admin_password" {
  description = "Password for Active Directory admin"
  type        = string
  sensitive   = true
} 