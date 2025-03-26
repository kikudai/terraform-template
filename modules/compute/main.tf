# NATインスタンス
resource "aws_instance" "nat" {
  ami                    = var.nat_ami
  instance_type          = "t4g.nano"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.nat_security_group_id]
  source_dest_check      = false  # NATインスタンスには必須の設定
  key_name               = var.key_name

  associate_public_ip_address = true

  # Option 2: 外部スクリプトファイルを使用
  user_data = file("${path.module}/scripts/setup.sh")

  tags = {
    Name = "NATInstance"
  }
}

# Windows ADサーバー
resource "aws_instance" "windows_ad" {
  ami                    = var.windows_ami
  instance_type          = "t3.small"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.windows_security_group_id]
  iam_instance_profile   = var.iam_instance_profile
  key_name              = var.key_name

  associate_public_ip_address = false

  private_ip = var.windows_ad_private_ip

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/userdata.ps1", {
    install_adds          = tostring(var.install_adds)
    domain_name           = var.domain_name
    domain_netbios_name   = var.domain_netbios_name
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

resource "tls_private_key" "windows_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.windows_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.windows_key.private_key_pem
  filename        = "${path.module}/windows_ad_key.pem"
  file_permission = "0600"
}

# Windows Entra Connect サーバー
resource "aws_instance" "windows_entra" {
  ami                    = var.windows_ami
  instance_type          = "t3.small"
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.windows_security_group_id]
  iam_instance_profile   = var.iam_instance_profile
  key_name              = var.key_name

  associate_public_ip_address = false

  private_ip = var.windows_entra_private_ip

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/entra_userdata.ps1", {
    domain_name           = var.domain_name
    domain_netbios_name   = var.domain_netbios_name
    domain_admin_password = var.domain_admin_password
    windows_ad_private_ip = var.windows_ad_private_ip
  }))

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  get_password_data = true

  tags = {
    Name = "WindowsEntraConnectServer"
  }
}

# IAMポリシーにSSMパラメータストアへのアクセス権を追加
resource "aws_iam_role_policy" "ssm_policy" {
  name = "ssm-parameter-access"
  role = aws_iam_role.ec2_role.id  # 既存のIAMロール

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/*"
      }
    ]
  })
}

# ADサーバーのパスワードをSSMパラメータストアに保存
resource "aws_ssm_parameter" "ad_admin_password" {
  name        = "/ad/admin/password"
  description = "AD Administrator Password"
  type        = "SecureString"
  value       = var.domain_admin_password  # または適切なパスワード取得方法

  tags = {
    Environment = "production"
  }
}
