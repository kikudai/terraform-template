variable "vpc_cidr" {
  type = string
}

variable "subnet_cidrs" {
  type = map(string)
}

variable "nat_instance_id" {
  description = "ID of the NAT instance"
  type        = string
}

variable "nat_instance_eni_id" {
  description = "ENI ID of the NAT instance"
  type        = string
}

variable "vpn_client_cidr" {
  type = string
}

variable "my_ip" {
  type = string
} 