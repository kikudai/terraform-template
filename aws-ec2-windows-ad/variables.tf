variable "aws_region" {
  default = "ap-northeast-1"
}

variable "windows_2019_ami" {
  description = "Windows Server 2019 日本語版の AMI ID"
  default     = "ami-033b26e504cfde89c" # 最新の日本語版 AMI を取得して設定
}

variable "key_name" {
  description = "EC2 にアクセスするための SSH キーペア"
  default     = "windows_ad_key"
}

variable "availability_zone" {
  description = "EC2 インスタンスを起動するアベイラビリティゾーン"
  default     = "ap-northeast-1a"
}

variable "spot_price" {
  description = "スポットインスタンスの最大価格"
  default     = "0.0357"
}
