# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "windows-ad-vpc"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "windows-ad-igw"
  }
}

# パブリックサブネット関連リソース
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "windows-ad-public-rt"
  }
}

resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs["public_1a"]
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "windows-ad-subnet-1"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs["public_1c"]
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name = "windows-ad-subnet-2"
  }
}

# プライベートサブネット関連リソース
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = var.nat_network_interface_id
  }

  tags = {
    Name = "windows-ad-private-rt"
  }
}

resource "aws_subnet" "private_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidrs["private_1a"]
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "windows-ad-private-subnet-1"
  }
}

# ルートテーブルの関連付け
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
}

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

  # ICMPを追加（pingなど）
  ingress {
    description = "ICMP from VPC and VPN clients"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  # VPC内部からのActive Directory関連ポート
  ingress {
    description = "Active Directory - DNS Name resolution for DC TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - DNS Name resolution for DC UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - Kerberos"
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - Kerberos UDP"
    from_port   = 88
    to_port     = 88
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - RPC Endpoint Mapper"
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - NetBIOS name resolution"
    from_port   = 137
    to_port     = 137
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - NetBIOS datagram service"
    from_port   = 138
    to_port     = 138
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - NetBIOS session service"
    from_port   = 139
    to_port     = 139
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - LDAP Connection to directory services"
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - LDAP Basic communication with DC"
    from_port   = 389
    to_port     = 389
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - SMB Communication with the Netlogon service"
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - LDAP SSL"
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - GC"
    from_port   = 3268
    to_port     = 3268
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Active Directory - GC SSL"
    from_port   = 3269
    to_port     = 3269
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "RDP from VPN clients"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.subnet_cidrs["private_1a"]]
  }

  # 動的RPCポート
  ingress {
    description = "Active Directory - Dynamic RPC Ports"
    from_port   = 49152
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # アウトバウンドはVPC内部の通信のみ許可
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr, var.vpn_client_cidr]
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
    cidr_blocks = [var.vpc_cidr]
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

# NATインスタンス用のセキュリティグループ
resource "aws_security_group" "nat" {
  name        = "nat_instance"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow inbound traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nat_instance"
  }
}

# Windows ADのセキュリティグループに追加
resource "aws_security_group_rule" "windows_ad_dns_outbound" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.windows_ad.id
}

resource "aws_security_group_rule" "windows_ad_https_outbound" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.windows_ad.id
}
