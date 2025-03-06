# Windows AD用のセキュリティグループ
resource "aws_security_group" "windows_ad" {
  name        = "windows_ad"
  description = "Security group for Windows AD server"
  vpc_id      = aws_vpc.main.id

  # RDPアクセスはVPN接続からのみ許可
  ingress {
    description = "RDP from VPN clients"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.vpn_client_cidr]
  }

  # Active Directory関連ポート
  ingress {
    description = "Active Directory - DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - LDAP"
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - LDAP SSL"
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - Kerberos"
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - Kerberos UDP"
    from_port   = 88
    to_port     = 88
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # アウトバウンドはVPC内部の通信のみ許可
  egress {
    description = "Internal VPC Communication only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = {
    Name = "windows_ad"
  }
}

# VPNエンドポイント用のセキュリティグループ
resource "aws_security_group" "vpn_endpoint" {
  name        = "vpn_endpoint"
  description = "Security group for VPN endpoint"
  vpc_id      = aws_vpc.main.id

  # VPN接続開始フェーズ: VPNクライアントツールからの初期接続用
  ingress {
    description = "VPN Initial Connection"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "VPN Initial Connection (UDP)"
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = [var.my_ip]
  }

  # VPC内部への通信のみ許可
  egress {
    description = "Access to VPC resources"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = {
    Name = "vpn_endpoint"
  }
}

# VPN接続確立後のクライアント用セキュリティグループ
resource "aws_security_group" "vpn_clients" {
  name        = "vpn_clients"
  description = "Security group for established VPN connections"
  vpc_id      = aws_vpc.main.id

  # VPN接続確立後フェーズ: VPC内のリソースへのアクセス
  ingress {
    description = "All traffic from VPN clients"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpn_client_cidr]
  }

  egress {
    description = "All traffic to VPN clients"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpn_client_cidr]
  }

  tags = {
    Name = "vpn_clients"
  }
}
