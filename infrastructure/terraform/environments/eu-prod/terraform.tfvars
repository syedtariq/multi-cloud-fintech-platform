# EU Production Environment Configuration
# GDPR Compliant Infrastructure

project_name = "fintech-trading-platform"
environment  = "prod"
aws_region   = "eu-west-1"

# Domain Configuration
domain_name = "eu.trading.example.com"

# Network Configuration (Different CIDR to avoid conflicts)
vpc_cidr = "10.1.0.0/16"
public_subnets    = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnets   = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
database_subnets  = ["10.1.20.0/24", "10.1.21.0/24", "10.1.22.0/24"]

# Monitoring
notification_endpoints = [
  "eu-platform-team@company.com",
  "gdpr-compliance@company.com"
]

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
rds_password = "CHANGE_ME_SECURE_PASSWORD_EU"

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

# Compliance Configuration (Enhanced for GDPR)
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
  cross_region_replication = false  # EU is standalone for GDPR
}