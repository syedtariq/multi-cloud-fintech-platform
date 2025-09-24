# Variables for Multi-Cloud Financial Services Platform

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "fintech-trading-platform"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_primary_region" {
  description = "AWS primary region"
  type        = string
  default     = "us-east-1"
}

variable "azure_dr_region" {
  description = "Azure disaster recovery region"
  type        = string
  default     = "East US 2"
}

variable "domain_name" {
  description = "Domain name for the trading platform"
  type        = string
  default     = "trading-platform.com"
}

variable "notification_endpoints" {
  description = "List of notification endpoints for alerts"
  type        = list(string)
  default     = ["platform-team@company.com"]
}

# Performance Configuration
variable "performance_config" {
  description = "Performance configuration parameters"
  type = object({
    target_latency_ms    = number
    target_throughput    = number
    max_concurrent_users = number
  })
  default = {
    target_latency_ms    = 100
    target_throughput    = 50000
    max_concurrent_users = 10000
  }
}

# EKS Configuration
variable "eks_config" {
  description = "EKS cluster configuration"
  type = object({
    cluster_version = string
    node_groups = map(object({
      instance_types = list(string)
      capacity_type  = string
      min_size      = number
      max_size      = number
      desired_size  = number
    }))
  })
  default = {
    cluster_version = "1.28"
    node_groups = {
      trading_engine = {
        instance_types = ["c5.2xlarge"]
        capacity_type  = "ON_DEMAND"
        min_size      = 3
        max_size      = 50
        desired_size  = 5
      }
      order_management = {
        instance_types = ["r5.xlarge"]
        capacity_type  = "ON_DEMAND"
        min_size      = 2
        max_size      = 30
        desired_size  = 3
      }
      risk_engine = {
        instance_types = ["c5.xlarge"]
        capacity_type  = "ON_DEMAND"
        min_size      = 2
        max_size      = 20
        desired_size  = 3
      }
      general_workloads = {
        instance_types = ["m5.large", "m5.xlarge"]
        capacity_type  = "SPOT"
        min_size      = 1
        max_size      = 10
        desired_size  = 2
      }
    }
  }
}

# Database Configuration
variable "database_config" {
  description = "Database configuration parameters"
  type = object({
    engine_version          = string
    instance_class         = string
    allocated_storage      = number
    max_allocated_storage  = number
    backup_retention_days  = number
    multi_az              = bool
    performance_insights  = bool
  })
  default = {
    engine_version          = "15.4"
    instance_class         = "db.r6g.xlarge"
    allocated_storage      = 100
    max_allocated_storage  = 1000
    backup_retention_days  = 30
    multi_az              = true
    performance_insights  = true
  }
}

# Cache Configuration
variable "cache_config" {
  description = "ElastiCache configuration parameters"
  type = object({
    engine_version     = string
    node_type         = string
    num_cache_nodes   = number
    parameter_group   = string
  })
  default = {
    engine_version     = "7.0"
    node_type         = "cache.r6g.large"
    num_cache_nodes   = 3
    parameter_group   = "default.redis7"
  }
}

# Security Configuration
variable "security_config" {
  description = "Security configuration parameters"
  type = object({
    enable_waf                = bool
    enable_shield_advanced    = bool
    enable_guardduty         = bool
    enable_security_hub      = bool
    enable_config            = bool
    enable_cloudtrail        = bool
  })
  default = {
    enable_waf                = true
    enable_shield_advanced    = true
    enable_guardduty         = true
    enable_security_hub      = true
    enable_config            = true
    enable_cloudtrail        = true
  }
}

# Compliance Configuration
variable "compliance_config" {
  description = "Compliance configuration parameters"
  type = object({
    soc2_compliance     = bool
    pci_dss_compliance  = bool
    gdpr_compliance     = bool
    audit_log_retention = number
  })
  default = {
    soc2_compliance     = true
    pci_dss_compliance  = true
    gdpr_compliance     = true
    audit_log_retention = 2555  # 7 years in days
  }
}

# Monitoring Configuration
variable "monitoring_config" {
  description = "Monitoring and alerting configuration"
  type = object({
    enable_detailed_monitoring = bool
    log_retention_days        = number
    create_dashboards         = bool
    alert_thresholds = object({
      cpu_utilization    = number
      memory_utilization = number
      disk_utilization   = number
      api_latency_ms     = number
      error_rate_percent = number
    })
  })
  default = {
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
}

# Disaster Recovery Configuration
variable "dr_config" {
  description = "Disaster recovery configuration"
  type = object({
    rto_minutes = number  # Recovery Time Objective
    rpo_minutes = number  # Recovery Point Objective
    backup_schedule = object({
      database_backup_window = string
      snapshot_retention     = number
    })
    cross_region_replication = bool
  })
  default = {
    rto_minutes = 15
    rpo_minutes = 5
    backup_schedule = {
      database_backup_window = "03:00-04:00"
      snapshot_retention     = 30
    }
    cross_region_replication = true
  }
}

# Cost Optimization Configuration
variable "cost_config" {
  description = "Cost optimization configuration"
  type = object({
    enable_spot_instances     = bool
    enable_reserved_instances = bool
    enable_savings_plans     = bool
    auto_scaling_enabled     = bool
    lifecycle_policies = object({
      s3_transition_days     = number
      s3_expiration_days     = number
      log_retention_days     = number
    })
  })
  default = {
    enable_spot_instances     = true
    enable_reserved_instances = true
    enable_savings_plans     = true
    auto_scaling_enabled     = true
    lifecycle_policies = {
      s3_transition_days     = 30
      s3_expiration_days     = 365
      log_retention_days     = 90
    }
  }
}

# Network Configuration
variable "network_config" {
  description = "Network configuration parameters"
  type = object({
    vpc_cidr = string
    availability_zones = list(string)
    subnets = object({
      public_cidrs   = list(string)
      private_cidrs  = list(string)
      database_cidrs = list(string)
      mgmt_cidrs     = list(string)
    })
    enable_nat_gateway    = bool
    enable_vpn_gateway    = bool
    enable_flow_logs      = bool
    enable_dns_hostnames  = bool
  })
  default = {
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
}

# Azure Configuration
variable "azure_config" {
  description = "Azure disaster recovery configuration"
  type = object({
    resource_group_name = string
    location           = string
    vnet_address_space = list(string)
    subnets = object({
      public_cidrs   = list(string)
      private_cidrs  = list(string)
      database_cidrs = list(string)
    })
    aks_config = object({
      kubernetes_version = string
      node_pools = map(object({
        vm_size    = string
        node_count = number
        min_count  = number
        max_count  = number
      }))
    })
    database_config = object({
      sku_name   = string
      storage_mb = number
      version    = string
    })
  })
  default = {
    resource_group_name = "fintech-trading-dr-rg"
    location           = "East US 2"
    vnet_address_space = ["10.1.0.0/16"]
    subnets = {
      public_cidrs   = ["10.1.1.0/24", "10.1.2.0/24"]
      private_cidrs  = ["10.1.10.0/24", "10.1.11.0/24"]
      database_cidrs = ["10.1.20.0/24", "10.1.21.0/24"]
    }
    aks_config = {
      kubernetes_version = "1.28"
      node_pools = {
        system = {
          vm_size    = "Standard_D2s_v3"
          node_count = 2
          min_count  = 1
          max_count  = 5
        }
        trading = {
          vm_size    = "Standard_D4s_v3"
          node_count = 1
          min_count  = 0
          max_count  = 10
        }
      }
    }
    database_config = {
      sku_name   = "GP_Standard_D2s_v3"
      storage_mb = 102400
      version    = "15"
    }
  }
}

# Tags Configuration
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Feature Flags
variable "feature_flags" {
  description = "Feature flags for enabling/disabling components"
  type = object({
    enable_azure_dr        = bool
    enable_cross_cloud_vpn = bool
    enable_advanced_monitoring = bool
    enable_chaos_engineering = bool
    enable_canary_deployments = bool
  })
  default = {
    enable_azure_dr        = true
    enable_cross_cloud_vpn = true
    enable_advanced_monitoring = true
    enable_chaos_engineering = false
    enable_canary_deployments = true
  }
}