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

# VPN用のセキュリティグループ
resource "aws_security_group" "vpn_sg" {
  name        = "VPNSecurityGroup"
  description = "Security group for VPN endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443  # VPN (UDP)
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443  # VPN (TCP)
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpn-sg"
  }
}

resource "aws_security_group" "vpn_endpoint" {
  name        = "vpn_endpoint"
  description = "Security group for VPN endpoint"
  vpc_id      = aws_vpc.main.id

  # VPNクライアントからの接続用（HTTPS）
  ingress {
    description = "VPN Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]  # VPN接続元IPのみ許可
  }

  # VPNクライアントからVPC内のリソースへのアクセス用
  egress {
    description = "Access to VPC resources"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]  # VPC内部への通信のみ許可
  }

  # DNS通信用（VPNクライアントのDNS解決に必要）
  egress {
    description = "DNS Query"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]  # VPC内のDNSサーバー用
  }

  tags = {
    Name = "vpn_endpoint"
  }
}

# VPNクライアント用のセキュリティグループ
resource "aws_security_group" "vpn_clients" {
  name        = "vpn_clients"
  description = "Security group for VPN clients"
  vpc_id      = aws_vpc.main.id

  # VPNクライアントからのアクセスを許可
  ingress {
    description = "Access from VPN clients"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpn_client_cidr]
  }

  egress {
    description = "Response to VPN clients"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpn_client_cidr]
  }

  tags = {
    Name = "vpn_clients"
  }
}
