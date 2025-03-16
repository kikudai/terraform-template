output "vpc_id" {
  value = module.network.vpc_id
}

output "windows_ad_private_ip" {
  value = module.compute.windows_ad_private_ip
}

# 他の必要な出力値を追加 