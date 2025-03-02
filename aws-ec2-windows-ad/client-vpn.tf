resource "aws_acm_certificate" "vpn_server" {
  private_key      = file("${path.module}/vpn-certs/server.key")
  certificate_body = file("${path.module}/vpn-certs/server.crt")
}

resource "aws_acm_certificate" "vpn_client" {
  private_key      = file("${path.module}/vpn-certs/client.key")
  certificate_body = file("${path.module}/vpn-certs/client.crt")
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "Windows AD VPN endpoint"
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  client_cidr_block     = "172.16.0.0/22"
  split_tunnel          = true
  vpc_id                = aws_vpc.main.id

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_client.arn
  }

  connection_log_options {
    enabled = false
  }

  tags = {
    Name = "windows-ad-vpn"
  }
}

resource "aws_ec2_client_vpn_network_association" "vpn_subnet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id             = aws_subnet.public.id
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = aws_vpc.main.cidr_block
  authorize_all_groups   = true
} 