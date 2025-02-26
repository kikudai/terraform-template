variable "aws_region" {
  default = "ap-northeast-1"
}

variable "windows_2019_ami" {
  default = "ami-0b2f6494ff0b07a0e" # Windows Server 2019 の適切な AMI ID を設定
}

variable "key_name" {
  description = "EC2 にアクセスするための SSH キーペア"
  default     = "windows_ad_key"
}
