# タグ関連の出力
output "common_tags" {
  description = "共通タグ"
  value       = local.common_tags
}

output "environment" {
  description = "環境名"
  value       = var.environment
}

output "region" {
  description = "AWSリージョン"
  value       = var.region
}
