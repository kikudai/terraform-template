output "windows_ad_instance_id" {
  description = "Windows AD サーバーのインスタンスID"
  value       = aws_instance.windows_ad.id
}

output "windows_ad_private_ip" {
  description = "Windows AD サーバーのプライベートIPアドレス"
  value       = aws_instance.windows_ad.private_ip
} 