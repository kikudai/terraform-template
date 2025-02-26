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

variable "availability_zone" {
  description = "EC2 インスタンスを起動するアベイラビリティゾーン"
  default     = "ap-northeast-1a"  # デフォルトの AZ
}

variable "spot_price" {
  description = "スポットインスタンスの最大価格"
  default     = "0.0357"  # デフォルトのスポット価格
}
