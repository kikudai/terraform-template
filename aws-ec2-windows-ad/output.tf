output "windows_ad_public_ip" {
  value = aws_spot_instance_request.windows_ad.public_ip
}

output "private_key_path" {
  value = "${path.module}/windows_ad_key.pem"
}

output "spot_instance_id" {
  value = aws_spot_instance_request.windows_ad.spot_instance_id
  description = "The ID of the EC2 instance launched via spot request"
}

output "get_windows_password_command" {
  value = "aws ec2 get-password-data --instance-id ${aws_spot_instance_request.windows_ad.spot_instance_id} --priv-launch-key windows_ad_key.pem"
  description = "Command to retrieve the Windows administrator password"
}
