# Outputs for Multi-Cloud Financial Services Platform (Modular)

# US Network Outputs
output "us_vpc_id" {
  description = "ID of the US VPC"
  value       = module.us_networking.vpc_id
}

output "us_public_subnet_ids" {
  description = "IDs of the US public subnets"
  value       = module.us_networking.public_subnet_ids
}

output "us_private_subnet_ids" {
  description = "IDs of the US private subnets"
  value       = module.us_networking.private_subnet_ids
}

output "us_database_subnet_ids" {
  description = "IDs of the US database subnets"
  value       = module.us_networking.database_subnet_ids
}

# EU Network Outputs (GDPR Compliance)
output "eu_vpc_id" {
  description = "ID of the EU VPC"
  value       = var.enable_eu_region ? module.eu_networking[0].vpc_id : null
}

output "eu_public_subnet_ids" {
  description = "IDs of the EU public subnets"
  value       = var.enable_eu_region ? module.eu_networking[0].public_subnet_ids : null
}

# Load Balancer Outputs
output "us_alb_dns_name" {
  description = "DNS name of the US Application Load Balancer"
  value       = module.us_compute.alb_dns_name
}

output "eu_alb_dns_name" {
  description = "DNS name of the EU Application Load Balancer"
  value       = var.enable_eu_region ? module.eu_compute[0].alb_dns_name : null
}

# EKS Outputs
output "us_eks_cluster_name" {
  description = "US EKS cluster name"
  value       = module.us_compute.eks_cluster_name
}

output "us_eks_cluster_endpoint" {
  description = "US EKS cluster endpoint"
  value       = module.us_compute.eks_cluster_endpoint
}

output "eu_eks_cluster_name" {
  description = "EU EKS cluster name"
  value       = var.enable_eu_region ? module.eu_compute[0].eks_cluster_name : null
}

output "eu_eks_cluster_endpoint" {
  description = "EU EKS cluster endpoint"
  value       = var.enable_eu_region ? module.eu_compute[0].eks_cluster_endpoint : null
}

# Database Outputs
output "us_rds_cluster_endpoint" {
  description = "US RDS Aurora cluster endpoint"
  value       = module.us_database.rds_cluster_endpoint
}

output "eu_rds_cluster_endpoint" {
  description = "EU RDS Aurora cluster endpoint (GDPR Compliant)"
  value       = var.enable_eu_region ? module.eu_database[0].rds_cluster_endpoint : null
}

# Cache Outputs
output "us_redis_primary_endpoint" {
  description = "US ElastiCache Redis primary endpoint"
  value       = module.us_database.redis_primary_endpoint
}

output "eu_redis_primary_endpoint" {
  description = "EU ElastiCache Redis primary endpoint"
  value       = var.enable_eu_region ? module.eu_database[0].redis_primary_endpoint : null
}

# Global CloudFront for Static Assets
output "global_cloudfront_distribution_id" {
  description = "Global CloudFront distribution ID for static assets"
  value       = aws_cloudfront_distribution.global_static.id
}

output "global_cloudfront_domain_name" {
  description = "Global CloudFront distribution domain name for static assets"
  value       = aws_cloudfront_distribution.global_static.domain_name
}

# API Endpoints (Direct ALB)
output "api_endpoint_us" {
  description = "US API endpoint (direct ALB)"
  value       = "https://api.${var.domain_name}"
}

output "api_endpoint_eu" {
  description = "EU API endpoint (direct ALB for EU users)"
  value       = var.enable_eu_region ? "https://api.${var.domain_name}" : null
}

output "static_assets_endpoint" {
  description = "Global static assets endpoint"
  value       = "https://static.${var.domain_name}"
}

# Security Outputs
output "us_waf_web_acl_id" {
  description = "US WAF Web ACL ID"
  value       = module.us_compute.waf_web_acl_id
}

output "eu_waf_web_acl_id" {
  description = "EU WAF Web ACL ID"
  value       = var.enable_eu_region ? module.eu_compute[0].waf_web_acl_id : null
}

# Storage Outputs
output "us_s3_bucket_name" {
  description = "US S3 bucket name for trading data"
  value       = module.us_database.s3_bucket_name
}

output "eu_s3_bucket_name" {
  description = "EU S3 bucket name for trading data"
  value       = var.enable_eu_region ? module.eu_database[0].s3_bucket_name : null
}

# Streaming Outputs
output "us_kinesis_stream_name" {
  description = "US Kinesis stream name for trading events"
  value       = module.us_database.kinesis_stream_name
}

output "us_sqs_queue_url" {
  description = "US SQS queue URL for order processing"
  value       = module.us_database.sqs_queue_url
}

# KMS Outputs
output "us_kms_cluster_key_arn" {
  description = "US KMS key ARN for EKS cluster encryption"
  value       = module.us_security.cluster_kms_key_arn
}

output "eu_kms_cluster_key_arn" {
  description = "EU KMS key ARN for EKS cluster encryption"
  value       = var.enable_eu_region ? module.eu_security[0].cluster_kms_key_arn : null
}

# Architecture Summary
output "architecture_summary" {
  description = "Summary of implemented architecture components"
  value = {
    # Network Layer
    vpc_cidr = "10.0.0.0/16"
    availability_zones = local.azs
    
    # Security Zones (as per network topology diagram)
    dmz_zone = {
      description = "Public subnets with ALB, NAT Gateways"
      subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    }
    
    application_zone = {
      description = "Private subnets with EKS worker nodes"
      subnets = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
    }
    
    data_zone = {
      description = "Database subnets with RDS, ElastiCache"
      subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
    }
    
    # Core Services (Multi-Region)
    us_services = {
      eks_cluster = module.us_compute.eks_cluster_name
      rds_aurora = module.us_database.rds_cluster_endpoint
      alb_endpoint = "api.${var.domain_name} (US users)"
    }
    
    eu_services = {
      eks_cluster = var.enable_eu_region ? module.eu_compute[0].eks_cluster_name : "Not deployed"
      rds_aurora = var.enable_eu_region ? module.eu_database[0].rds_cluster_endpoint : "Not deployed"
      alb_endpoint = var.enable_eu_region ? "api.${var.domain_name} (EU users)" : "Not deployed"
    }
    
    global_services = {
      cloudfront_static = aws_cloudfront_distribution.global_static.domain_name
      static_assets = "static.${var.domain_name}"
      route53_geolocation = "EU users → EU ALB, Others → US ALB"
    }
    
    gdpr_compliance = {
      eu_region_enabled = var.enable_eu_region
      data_residency = "EU users routed to eu-west-1 ALB directly"
      geolocation_routing = "Route 53 continent-based API routing"
      static_assets = "Global CloudFront for performance"
      api_latency = "<100ms via direct ALB routing"
    }
    
    # Performance Targets
    performance_targets = {
      latency_target = "<100ms order execution"
      throughput_target = "50K-250K TPS"
      concurrent_users = "10K-50K users"
      availability = "99.99% uptime SLA"
    }
    
    # Compliance Implementation
    compliance_status = {
      soc2_type_ii = "Security controls implemented across regions"
      pci_dss_level_1 = "Encryption and access controls in both regions"
      gdpr = var.enable_eu_region ? "EU region deployed with data residency" : "EU region not enabled"
      zero_trust = "Network segmentation and mTLS in both regions"
      data_residency = var.enable_eu_region ? "EU users data processed in eu-west-1" : "All data in us-east-1"
    }
  }
}