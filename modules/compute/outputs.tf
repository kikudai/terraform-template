output "nat_instance_id" {
  description = "NAT インスタンスのID"
  value       = aws_instance.nat.id
}

output "nat_network_interface_id" {
  description = "NAT インスタンスのプライマリネットワークインターフェースID"
  value       = aws_instance.nat.primary_network_interface_id
}

output "windows_ad_instance_id" {
  description = "Windows AD サーバーのインスタンスID"
  value       = aws_instance.windows_ad.id
}

output "windows_ad_private_ip" {
  description = "Windows AD サーバーのプライベートIPアドレス"
  value       = aws_instance.windows_ad.private_ip
} 