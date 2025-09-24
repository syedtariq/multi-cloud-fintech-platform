output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.trading_api.id
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "https://api.${var.domain_name}"
}

output "api_gateway_stage_url" {
  description = "Stage URL of the API Gateway"
  value       = aws_api_gateway_deployment.trading_deployment.invoke_url
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  description = "Route 53 name servers"
  value       = aws_route53_zone.main.name_servers
}

output "health_check_id" {
  description = "Route 53 health check ID"
  value       = aws_route53_health_check.api_health.id
}