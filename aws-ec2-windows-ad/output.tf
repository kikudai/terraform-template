output "windows_ad_public_ip" {
  value = aws_instance.windows_ad.public_ip
}

output "private_key_path" {
  value = "${path.module}/windows_ad_key.pem"
}

output "vpn_endpoint_dns" {
  value = aws_ec2_client_vpn_endpoint.vpn.dns_name
}

output "instance_id" {
  value = aws_instance.windows_ad.id
}

output "get_windows_password_command" {
  value = "aws ec2 get-password-data --instance-id ${aws_instance.windows_ad.id} --priv-launch-key windows_ad_key.pem"
  description = "Command to retrieve the Windows administrator password"
}
