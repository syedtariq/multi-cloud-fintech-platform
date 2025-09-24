output "alb_dns_name" {
  description = "DNS name of the US ALB"
  value       = module.compute.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the US ALB"
  value       = module.compute.alb_zone_id
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name for CloudFront"
  value       = module.database.s3_bucket_domain_name
}