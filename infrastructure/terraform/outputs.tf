# Outputs for Multi-Cloud Financial Services Platform

# Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "management_subnet_ids" {
  description = "IDs of the management subnets"
  value       = aws_subnet.management[*].id
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

# EKS Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

# Database Outputs
output "rds_cluster_id" {
  description = "RDS Aurora cluster ID"
  value       = aws_rds_cluster.main.id
}

output "rds_cluster_endpoint" {
  description = "RDS Aurora cluster endpoint"
  value       = aws_rds_cluster.main.endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "RDS Aurora cluster reader endpoint"
  value       = aws_rds_cluster.main.reader_endpoint
}

# Cache Outputs
output "redis_cluster_id" {
  description = "ElastiCache Redis cluster ID"
  value       = aws_elasticache_replication_group.main.id
}

output "redis_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

# Route 53 Outputs
output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  description = "Route 53 name servers"
  value       = aws_route53_zone.main.name_servers
}

# Security Outputs
output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

# Storage Outputs
output "s3_bucket_name" {
  description = "S3 bucket name for trading data"
  value       = aws_s3_bucket.data.bucket
}

output "kinesis_stream_name" {
  description = "Kinesis stream name for trading events"
  value       = aws_kinesis_stream.trading_events.name
}

output "sqs_queue_url" {
  description = "SQS queue URL for order processing"
  value       = aws_sqs_queue.order_processing.url
}

# Management Outputs
output "bastion_instance_id" {
  description = "Bastion host instance ID"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = aws_instance.bastion.public_ip
}

# KMS Outputs
output "kms_cluster_key_id" {
  description = "KMS key ID for EKS cluster encryption"
  value       = aws_kms_key.cluster.key_id
}

output "kms_database_key_id" {
  description = "KMS key ID for database encryption"
  value       = aws_kms_key.database.key_id
}

# Architecture Alignment Summary
output "architecture_summary" {
  description = "Summary of implemented architecture components"
  value = {
    # Network Layer
    vpc_cidr = local.vpc_cidr
    availability_zones = local.azs
    
    # Security Zones (as per network topology diagram)
    dmz_zone = {
      description = "Public subnets with ALB, NAT Gateways"
      subnets = local.public_subnets
    }
    
    application_zone = {
      description = "Private subnets with EKS worker nodes"
      subnets = local.private_subnets
    }
    
    data_zone = {
      description = "Database subnets with RDS, ElastiCache"
      subnets = local.database_subnets
    }
    
    management_zone = {
      description = "Management subnets with bastion host"
      subnets = local.mgmt_subnets
    }
    
    # Core Services (as per high-level architecture diagram)
    compute_services = {
      eks_cluster = aws_eks_cluster.main.name
      node_groups = "Trading Engine, Order Management, Risk Engine pods"
    }
    
    data_services = {
      rds_aurora = aws_rds_cluster.main.cluster_identifier
      elasticache_redis = aws_elasticache_replication_group.main.replication_group_id
      kinesis_streams = aws_kinesis_stream.trading_events.name
      s3_storage = aws_s3_bucket.data.bucket
      sqs_queues = aws_sqs_queue.order_processing.name
    }
    
    security_services = {
      waf = aws_wafv2_web_acl.main.name
      cloudfront_cdn = aws_cloudfront_distribution.main.id
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