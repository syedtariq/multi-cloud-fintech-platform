# Production Environment Variables
# Multi-Cloud Financial Services Platform

# Basic Configuration
project_name         = "fintech-trading-platform"
environment          = "prod"
aws_primary_region   = "us-east-1"
aws_eu_region        = "eu-west-1"
enable_eu_region     = true
domain_name          = "trading-platform.com"

# Performance Configuration
performance_config = {
  target_latency_ms    = 100
  target_throughput    = 50000
  max_concurrent_users = 10000
}

# EKS Configuration
eks_config = {
  cluster_version = "1.28"
  node_groups = {
    trading_engine = {
      instance_types = ["c5.2xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size      = 3
      max_size      = 50
      desired_size  = 6
    }
    order_management = {
      instance_types = ["r5.xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size      = 2
      max_size      = 30
      desired_size  = 4
    }
    risk_engine = {
      instance_types = ["c5.xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size      = 2
      max_size      = 20
      desired_size  = 3
    }
  }
}

# Database Configuration
database_config = {
  engine_version          = "15.4"
  instance_class         = "db.r6g.large"
  allocated_storage      = 100
  max_allocated_storage  = 1000
  backup_retention_days  = 30
  multi_az              = true
  performance_insights  = true
}

# Cache Configuration
cache_config = {
  engine_version     = "7.0"
  node_type         = "cache.r6g.large"
  num_cache_nodes   = 2
  parameter_group   = "default.redis7"
}

# Security Configuration
security_config = {
  enable_waf                = true
  enable_shield_advanced    = false
  enable_guardduty         = true
  enable_security_hub      = true
  enable_config            = true
  enable_cloudtrail        = true
}

# Compliance Configuration
compliance_config = {
  soc2_compliance     = true
  pci_dss_compliance  = true
  gdpr_compliance     = true
  audit_log_retention = 2555  # 7 years in days
}

# Monitoring Configuration
monitoring_config = {
  enable_detailed_monitoring = true
  log_retention_days        = 90
  create_dashboards         = true
  alert_thresholds = {
    cpu_utilization    = 80
    memory_utilization = 85
    disk_utilization   = 90
    api_latency_ms     = 100
    error_rate_percent = 1
  }
}

# Disaster Recovery Configuration
dr_config = {
  rto_minutes = 15
  rpo_minutes = 5
  backup_schedule = {
    database_backup_window = "03:00-04:00"
    snapshot_retention     = 30
  }
  cross_region_replication = true
}

# Cost Optimization Configuration
cost_config = {
  enable_spot_instances     = false  # Production uses on-demand
  enable_reserved_instances = true
  enable_savings_plans     = true
  auto_scaling_enabled     = true
  lifecycle_policies = {
    s3_transition_days     = 30
    s3_expiration_days     = 2555  # 7 years for compliance
    log_retention_days     = 90
  }
}

# Network Configuration
network_config = {
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  subnets = {
    public_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_cidrs  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
    database_cidrs = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
    mgmt_cidrs     = ["10.0.30.0/24", "10.0.31.0/24"]
  }
  enable_nat_gateway    = true
  enable_vpn_gateway    = true
  enable_flow_logs      = true
  enable_dns_hostnames  = true
}

# Feature Flags
feature_flags = {
  enable_azure_dr        = false  # Excluded per requirements
  enable_cross_cloud_vpn = false  # Excluded per requirements
  enable_advanced_monitoring = true
  enable_chaos_engineering = false  # Not for production
  enable_canary_deployments = true
}

# Notification Endpoints
notification_endpoints = [
  "platform-team@company.com",
  "security-team@company.com",
  "finops-team@company.com"
]

# Additional Tags
additional_tags = {
  BusinessUnit = "Trading"
  CostCenter   = "Engineering"
  Compliance   = "SOC2-PCI-GDPR"
  Criticality  = "High"
  DataClass    = "Confidential"
}