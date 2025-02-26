provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone # 変数で AZ を管理
}

resource "aws_spot_instance_request" "windows_ad" {
  ami                    = var.windows_2019_ami
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.windows_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = aws_key_pair.generated_key.key_name  # 生成したキーペアを適用
  spot_price             = var.spot_price
  wait_for_fulfillment   = true

  user_data = file("userdata.ps1")

  tags = {
    Name = "WindowsADServer"
  }
}
