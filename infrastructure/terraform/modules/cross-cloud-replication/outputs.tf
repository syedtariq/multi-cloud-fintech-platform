output "dms_replication_instance_arn" {
  description = "DMS replication instance ARN"
  value       = aws_dms_replication_instance.cross_cloud.replication_instance_arn
}

output "vpn_connection_id" {
  description = "VPN connection ID"
  value       = var.enable_azure_dr ? aws_vpn_connection.azure[0].id : null
}

output "lambda_function_arn" {
  description = "Redis replication Lambda function ARN"
  value       = var.enable_azure_dr ? aws_lambda_function.redis_replication[0].arn : null
}