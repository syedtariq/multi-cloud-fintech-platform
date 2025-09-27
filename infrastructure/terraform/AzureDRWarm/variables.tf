# Azure DR Variables
# Multi-Cloud Financial Services Platform - Disaster Recovery

# Basic Configuration
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

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "azure_location" {
  description = "Azure region for DR"
  type        = string
  default     = "East US 2"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "trading-platform.com"
}

# Network Configuration
variable "vnet_cidr" {
  description = "CIDR block for Azure VNet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type = object({
    app_gateway = string
    aks         = string
    database    = string
    gateway     = string
  })
  default = {
    app_gateway = "10.1.1.0/24"
    aks         = "10.1.10.0/24"
    database    = "10.1.20.0/24"
    gateway     = "10.1.30.0/24"
  }
}

# AKS Configuration
variable "enable_warm_standby" {
  description = "Enable warm standby mode for AKS"
  type        = bool
  default     = false
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "aks_max_nodes" {
  description = "Maximum number of AKS nodes"
  type        = number
  default     = 10
}

# Database Configuration
variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "postgres_sku" {
  description = "PostgreSQL SKU"
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
}

# Monitoring Configuration
variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 90
}

variable "notification_endpoints" {
  description = "Email addresses for notifications"
  type        = list(string)
  default = [
    "platform-team@company.com",
    "security-team@company.com"
  ]
}

# Cross-Cloud VPN Configuration
variable "enable_cross_cloud_vpn" {
  description = "Enable cross-cloud VPN connection"
  type        = bool
  default     = false
}

variable "aws_vpn_gateway_ip" {
  description = "AWS VPN Gateway public IP"
  type        = string
  default     = ""
}

variable "vpn_shared_key" {
  description = "Shared key for VPN connection"
  type        = string
  sensitive   = true
  default     = ""
}

# DR Configuration
variable "dr_config" {
  description = "Disaster recovery configuration"
  type = object({
    rto_minutes                = number
    rpo_minutes                = number
    cross_region_replication   = bool
    backup_retention_days      = number
  })
  default = {
    rto_minutes              = 15
    rpo_minutes              = 5
    cross_region_replication = true
    backup_retention_days    = 30
  }
}