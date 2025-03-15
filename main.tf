provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
#  cidr_block           = "172.16.0.0/16"
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
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
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

# プライベートサブネット用のルートテーブル
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = module.compute.nat_network_interface_id
  }

  tags = {
    Name = "windows-ad-private-rt"
  }
}

# プライベートサブネットのルートテーブル関連付け
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private.id
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

module "compute" {
  source = "./modules/compute"

  nat_ami                  = var.nat_ami
  public_subnet_id         = aws_subnet.public_1a.id
  nat_security_group_id    = aws_security_group.nat.id
  key_name                = aws_key_pair.generated_key.key_name
  
  windows_ami             = var.windows_ami
  private_subnet_id       = aws_subnet.private_1a.id
  windows_security_group_id = aws_security_group.windows_ad.id
  iam_instance_profile    = module.iam.instance_profile_name
  
  userdata_template_path  = "${path.module}/userdata.ps1"
  install_adds           = var.install_adds
  domain_name           = var.domain_name
  domain_netbios_name   = var.domain_netbios_name
  domain_admin_password = var.domain_admin_password
}

module "iam" {
  source = "./modules/iam"
}

module "vpn" {
  source = "./modules/vpn"

  vpc_id = aws_vpc.main.id

  # セキュリティグループ
  security_group_ids = [aws_security_group.vpn_endpoint.id]


  # Active Directory関連
  dns_servers = [module.compute.windows_ad_private_ip]

  domain_name          = var.domain_name

  # ネットワーク関連
  subnet_id_1              = aws_subnet.public_1c.id
  subnet_id_2            = aws_subnet.public_1c.id
  target_network_cidr    = aws_vpc.main.cidr_block

  vpn_client_cidr  = var.vpn_client_cidr
}
