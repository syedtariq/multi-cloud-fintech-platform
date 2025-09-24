variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "fintech-trading-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnets" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
}

variable "notification_endpoints" {
  description = "SNS notification endpoints"
  type        = list(string)
  default     = []
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "enable_azure_dr" {
  description = "Enable Azure disaster recovery"
  type        = bool
  default     = false
}

variable "azure_vpn_gateway_ip" {
  description = "Azure VPN Gateway public IP"
  type        = string
  default     = ""
}

variable "azure_postgres_fqdn" {
  description = "Azure PostgreSQL FQDN"
  type        = string
  default     = ""
}

variable "azure_postgres_password" {
  description = "Azure PostgreSQL password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_redis_hostname" {
  description = "Azure Redis hostname"
  type        = string
  default     = ""
}

variable "azure_redis_key" {
  description = "Azure Redis access key"
  type        = string
  sensitive   = true
  default     = ""
}

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
}

variable "database_config" {
  description = "Database configuration"
  type = object({
    engine_version          = string
    instance_class         = string
    allocated_storage      = number
    max_allocated_storage  = number
    backup_retention_days  = number
    multi_az              = bool
    performance_insights  = bool
  })
}

variable "cache_config" {
  description = "Cache configuration"
  type = object({
    engine_version     = string
    node_type         = string
    num_cache_nodes   = number
    parameter_group   = string
  })
}

variable "security_config" {
  description = "Security configuration"
  type = object({
    enable_waf                = bool
    enable_shield_advanced    = bool
    enable_guardduty         = bool
    enable_security_hub      = bool
    enable_config            = bool
    enable_cloudtrail        = bool
  })
}

variable "compliance_config" {
  description = "Compliance configuration"
  type = object({
    soc2_compliance     = bool
    pci_dss_compliance  = bool
    gdpr_compliance     = bool
    audit_log_retention = number
  })
}

variable "monitoring_config" {
  description = "Monitoring configuration"
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
}

variable "dr_config" {
  description = "Disaster recovery configuration"
  type = object({
    rto_minutes = number
    rpo_minutes = number
    backup_schedule = object({
      database_backup_window = string
      snapshot_retention     = number
    })
    cross_region_replication = bool
  })
}