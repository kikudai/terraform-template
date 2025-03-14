output "windows_ad_public_ip" {
  value = module.compute.windows_ad_instance_id
}

output "windows_ad_private_ip" {
  value = module.compute.windows_ad_private_ip
  description = "The private IP address of the Windows AD instance"
}

output "nat_instance_id" {
  description = "NAT インスタンスのID"
  value       = module.compute.nat_instance_id
}

output "nat_network_interface_id" {
  description = "NAT インスタンスのネットワークインターフェースID"
  value       = module.compute.nat_network_interface_id
}

output "private_key_path" {
  value = "${path.module}/windows_ad_key.pem"
}

output "vpn_endpoint_dns" {
  value = aws_ec2_client_vpn_endpoint.vpn.dns_name
}

output "instance_id" {
  value = module.compute.windows_ad_instance_id
  description = "The ID of the EC2 instance"
}

output "get_windows_password_command" {
  value = "aws ec2 get-password-data --instance-id ${module.compute.windows_ad_instance_id} --priv-launch-key windows_ad_key.pem"
  description = "Command to retrieve the Windows administrator password"
}
