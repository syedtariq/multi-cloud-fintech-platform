# Outputs for Multi-Cloud Financial Services Platform (Modular)

# Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.networking.database_subnet_ids
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

# EKS Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.compute.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.compute.eks_cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.security.eks_cluster_sg_id
}

# Database Outputs
output "rds_cluster_endpoint" {
  description = "RDS Aurora cluster endpoint"
  value       = module.database.rds_cluster_endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "RDS Aurora cluster reader endpoint"
  value       = module.database.rds_cluster_reader_endpoint
}

# Cache Outputs
output "redis_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = module.database.redis_primary_endpoint
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.compute.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.compute.cloudfront_domain_name
}

# Security Outputs
output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = module.compute.waf_web_acl_id
}

# Storage Outputs
output "s3_bucket_name" {
  description = "S3 bucket name for trading data"
  value       = module.database.s3_bucket_name
}

output "kinesis_stream_name" {
  description = "Kinesis stream name for trading events"
  value       = module.database.kinesis_stream_name
}

output "sqs_queue_url" {
  description = "SQS queue URL for order processing"
  value       = module.database.sqs_queue_url
}

# KMS Outputs
output "kms_cluster_key_arn" {
  description = "KMS key ARN for EKS cluster encryption"
  value       = module.security.cluster_kms_key_arn
}

output "kms_database_key_arn" {
  description = "KMS key ARN for database encryption"
  value       = module.security.database_kms_key_arn
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
    
    # Core Services (as per high-level architecture diagram)
    compute_services = {
      eks_cluster = module.compute.eks_cluster_name
      node_groups = "Trading Engine, Order Management, Risk Engine pods"
    }
    
    data_services = {
      rds_aurora = "Aurora PostgreSQL cluster"
      elasticache_redis = "Redis cluster"
      kinesis_streams = module.database.kinesis_stream_name
      s3_storage = module.database.s3_bucket_name
      sqs_queues = "Order processing queue"
    }
    
    security_services = {
      waf = "Web Application Firewall"
      cloudfront_cdn = module.compute.cloudfront_distribution_id
      kms_encryption = "Cluster and Database keys configured"
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
      soc2_type_ii = "Security controls implemented"
      pci_dss_level_1 = "Encryption and access controls"
      gdpr = "Data residency and privacy by design"
      zero_trust = "Network segmentation and mTLS"
    }
  }
}