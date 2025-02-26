output "windows_ad_private_ip" {
  value = aws_instance.windows_ad.private_ip
}

output "windows_ad_public_ip" {
  value = aws_instance.windows_ad.public_ip
}
