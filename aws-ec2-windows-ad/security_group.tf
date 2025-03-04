# Windows AD用のセキュリティグループ
resource "aws_security_group" "windows_sg" {
  name        = "WindowsADSecurityGroup"
  description = "Security group for Windows AD server"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3389  # RDP
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 53  # DNS
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53  # DNS (UDP)
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 88  # Kerberos
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 88  # Kerberos (UDP)
    to_port     = 88
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 389  # LDAP
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 636  # LDAPS
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 445  # SMB
    to_port     = 445
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
    Name = "windows-ad-sg"
  }
}

# VPN用のセキュリティグループ
resource "aws_security_group" "vpn_sg" {
  name        = "VPNSecurityGroup"
  description = "Security group for VPN endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443  # VPN
    to_port     = 443
    protocol    = "udp"
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
