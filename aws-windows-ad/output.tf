output "windows_ad_public_ip" {
  value = aws_spot_instance_request.windows_ad.public_ip
}

output "private_key_path" {
  value = "${path.module}/windows_ad_key.pem"
}
