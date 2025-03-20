output "nat_instance_id" {
  description = "ID of the NAT instance"
  value       = aws_instance.nat.id
}

output "windows_ad_instance_id" {
  description = "Windows AD サーバーのインスタンスID"
  value       = aws_instance.windows_ad.id
}

output "windows_ad_private_ip" {
  description = "Windows AD サーバーのプライベートIPアドレス"
  value       = aws_instance.windows_ad.private_ip
}

output "nat_instance_eni_id" {
  description = "Primary ENI ID of the NAT instance"
  value       = aws_instance.nat.primary_network_interface_id
} 