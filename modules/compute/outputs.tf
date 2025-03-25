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

output "nat_private_ip" {
  description = "Windows AD サーバーのプライベートIPアドレス"
  value       = aws_instance.nat.private_ip
}

output "nat_instance_eni_id" {
  description = "Primary ENI ID of the NAT instance"
  value       = aws_instance.nat.primary_network_interface_id
} 

# Entra Connect サーバーのプライベートIPを出力
output "windows_entra_private_ip" {
  value = aws_instance.windows_entra.private_ip
  description = "Private IP of Windows Entra Connect Server"
} 
