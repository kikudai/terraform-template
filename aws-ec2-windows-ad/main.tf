provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
#  cidr_block           = "172.16.0.0/16"
  cidr_block           = "10.16.0.0/16"
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

# パブリックルートテーブル
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

# ルートテーブルの関連付け
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
#  cidr_block              = "172.16.1.0/24"
  cidr_block              = "10.16.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "windows-ad-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
#  cidr_block              = "172.16.2.0/24"
  cidr_block              = "10.16.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name = "windows-ad-subnet-2"
  }
}

# プライベートサブネット用のルートテーブル
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }

  tags = {
    Name = "windows-ad-private-rt"
  }
}

# プライベートサブネットのルートテーブル関連付け
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.main.id
#  cidr_block              = "172.16.3.0/24"
  cidr_block              = "10.16.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "windows-ad-private-subnet-1"
  }
}

resource "aws_instance" "windows_ad" {
  ami                    = var.windows_ami
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.windows_ad.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = aws_key_pair.generated_key.key_name

  associate_public_ip_address = false

  user_data_base64 = base64encode(templatefile("${path.module}/userdata.ps1", {
    install_adds         = tostring(var.install_adds)
    domain_name         = var.domain_name
    domain_netbios_name = var.domain_netbios_name
    domain_admin_password = var.domain_admin_password
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"  # IMDSv2を必須に設定
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "WindowsADServer"
  }
}

