variable "vpc_cidr" {
  type = string
}

variable "subnet_cidrs" {
  type = map(string)
}

variable "vpn_client_cidr" {
  type = string
}

variable "my_ip" {
  type = string
} 