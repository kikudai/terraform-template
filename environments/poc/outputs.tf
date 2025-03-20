output "vpc_id" {
  value = module.network.vpc_id
}

output "windows_ad_private_ip" {
  value = module.compute.windows_ad_private_ip
}

output "nat_private_ip" {
  value = module.compute.nat_private_ip
}

output "vpn_endpoint_dns" {
  description = "VPNエンドポイントのDNS名"
  value = module.vpn.vpn_endpoint_dns
}

output "get_windows_password_command" {
  value = "aws ec2 get-password-data --instance-id ${module.compute.windows_ad_instance_id} --priv-launch-key ../../modules/compute/windows_ad_key.pem"
  description = "Command to retrieve the Windows administrator password"
}
