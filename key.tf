resource "tls_private_key" "windows_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name  # `variables.tf` の変数を参照
  public_key = tls_private_key.windows_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.windows_key.private_key_pem
  filename = "${path.module}/windows_ad_key.pem"
  file_permission = "0600"
}
