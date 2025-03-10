resource "null_resource" "generate_vpn_certs" {
  triggers = {
    # 証明書を一度だけ生成するために固定値を使用
    run_once = "generate_certs"
  }

  provisioner "local-exec" {
    # 証明書が存在しない場合のみ生成するように条件を追加
    command = <<-EOT
      if [ ! -f "${path.module}/vpn-certs/server.crt" ]; then
        chmod +x ${path.module}/generate-vpn-certs.sh
        ${path.module}/generate-vpn-certs.sh
      fi
    EOT
  }
}

resource "aws_acm_certificate" "vpn_server" {
  depends_on = [null_resource.generate_vpn_certs]
  private_key       = file("${path.module}/vpn-certs/server.key")
  certificate_body  = file("${path.module}/vpn-certs/server.crt")
  certificate_chain = file("${path.module}/vpn-certs/ca.crt")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "vpn_client" {
  depends_on = [null_resource.generate_vpn_certs]
  private_key       = file("${path.module}/vpn-certs/client.key")
  certificate_body  = file("${path.module}/vpn-certs/client.crt")
  certificate_chain = file("${path.module}/vpn-certs/ca.crt")
}

resource "aws_cloudwatch_log_group" "vpn_log" {
  name              = "/aws/vpn/windows-ad-vpn"
  retention_in_days = 30

  tags = {
    Name = "windows-ad-vpn-logs"
  }
}

resource "aws_cloudwatch_log_stream" "vpn_stream" {
  name           = "vpn-connection-logs"
  log_group_name = aws_cloudwatch_log_group.vpn_log.name
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "Windows AD VPN endpoint"
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  client_cidr_block     = "172.17.0.0/22"
  split_tunnel          = true
  vpc_id                = aws_vpc.main.id
  security_group_ids    = [aws_security_group.vpn_endpoint.id]
  transport_protocol    = "tcp"
  vpn_port             = 443
  session_timeout_hours = 8

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_client.arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn_log.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn_stream.name
  }

  dns_servers = [aws_instance.windows_ad.private_ip]
  
  tags = {
    Name = "windows-ad-vpn"
  }
}

resource "aws_ec2_client_vpn_network_association" "vpn_subnet" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id             = aws_subnet.public_1.id
}

resource "aws_ec2_client_vpn_network_association" "vpn_subnet_2" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id             = aws_subnet.public_2.id
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = aws_vpc.main.cidr_block
  authorize_all_groups   = true

  timeouts {
    create = "20m"  # タイムアウトを20分に延長
    delete = "20m"
  }
}

resource "null_resource" "create_ovpn" {
  depends_on = [
    aws_ec2_client_vpn_endpoint.vpn,
    aws_ec2_client_vpn_network_association.vpn_subnet,
    aws_ec2_client_vpn_authorization_rule.vpn_auth_rule
  ]

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "chmod +x ${path.module}/create-vpn-ovpn.sh && ${path.module}/create-vpn-ovpn.sh"
  }
} 