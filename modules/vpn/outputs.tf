output "client_vpn_endpoint_id" {
  description = "Client VPNエンドポイントのID"
  value       = aws_ec2_client_vpn_endpoint.vpn.id
}

output "client_vpn_endpoint_arn" {
  description = "Client VPNエンドポイントのARN"
  value       = aws_ec2_client_vpn_endpoint.vpn.arn
}

output "vpn_server_certificate_arn" {
  description = "VPNサーバー証明書のARN"
  value       = aws_acm_certificate.vpn_server.arn
}

output "vpn_client_certificate_arn" {
  description = "VPNクライアント証明書のARN"
  value       = aws_acm_certificate.vpn_client.arn
}

output "vpn_endpoint_dns" {
  description = "VPNエンドポイントのDNS名"
  value       = aws_ec2_client_vpn_endpoint.vpn.dns_name
}

output "vpn_endpoint_id" {
  description = "VPNエンドポイントのID"
  value       = aws_ec2_client_vpn_endpoint.vpn.id
} 