# RSA 2048-bit の秘密鍵を Terraform で自動生成
resource "tls_private_key" "windows_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# AWS にキーペアを登録
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.windows_key.public_key_openssh
}

variable "key_name" {
  description = "EC2 にアクセスするための SSH キーペア"
  default     = "windows_ad_key"  # デフォルトのキーペア名を指定
}

# 生成した秘密鍵をローカルに保存
resource "local_file" "private_key" {
  content  = tls_private_key.windows_key.private_key_pem
  filename = "${path.module}/windows_ad_key.pem"
  file_permission = "0600"
}
