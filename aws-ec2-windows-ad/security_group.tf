# Windows AD用のセキュリティグループ
resource "aws_security_group" "windows_ad" {
  name        = "windows_ad"
  description = "Security group for Windows AD server"
  vpc_id      = aws_vpc.main.id

  # VPNクライアントからの全てのトラフィックを許可
  ingress {
    description = "All traffic from VPN clients"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpn_client_cidr]
  }

  # VPC内部からのActive Directory関連ポート
  ingress {
    description = "Active Directory - DNS Name resolution for DC TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - DNS Name resolution for DC UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
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

  ingress {
    description = "Active Directory - RPC Endpoint Mapper"
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - NetBIOS name resolution"
    from_port   = 137
    to_port     = 137
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - NetBIOS datagram service"
    from_port   = 138
    to_port     = 138
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - NetBIOS session service"
    from_port   = 139
    to_port     = 139
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - LDAP Connection to directory services"
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - LDAP Basic communication with DC"
    from_port   = 389
    to_port     = 389
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - SMB Communication with the Netlogon service"
    from_port   = 445
    to_port     = 445
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
    description = "Active Directory - GC"
    from_port   = 3268
    to_port     = 3268
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Active Directory - GC SSL"
    from_port   = 3269
    to_port     = 3269
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # 動的RPCポートの追加
  ingress {
    description = "Active Directory - Dynamic RPC Ports"
    from_port   = 49152
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # アウトバウンドはVPC内部の通信のみ許可
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block, var.vpn_client_cidr]
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
