output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_1a_id" {
  value = aws_subnet.public_1a.id
}

output "public_subnet_1c_id" {
  value = aws_subnet.public_1c.id
}

output "private_subnet_1a_id" {
  value = aws_subnet.private_1a.id
}

output "windows_ad_sg_id" {
  value = aws_security_group.windows_ad.id
}

output "vpn_endpoint_sg_id" {
  value = aws_security_group.vpn_endpoint.id
}

output "nat_sg_id" {
  value = aws_security_group.nat.id
}

output "vpn_clients_sg_id" {
  value = aws_security_group.vpn_clients.id
} 