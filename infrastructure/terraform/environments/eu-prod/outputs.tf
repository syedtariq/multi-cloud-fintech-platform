output "alb_dns_name" {
  description = "DNS name of the EU ALB"
  value       = module.compute.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the EU ALB"
  value       = module.compute.alb_zone_id
}