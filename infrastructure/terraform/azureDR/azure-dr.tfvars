# Azure DR Environment Variables
# Multi-Cloud Financial Services Platform - Disaster Recovery

# Basic Configuration
project_name = "fintech-trading-platform"
environment  = "prod"
azure_location = "East US 2"
domain_name = "trading-platform.com"

# Azure Subscription Configuration
# azure_subscription_id = "your-azure-subscription-id"  # Set via environment variable
# azure_tenant_id       = "your-azure-tenant-id"        # Set via environment variable

# Network Configuration
vnet_cidr = "10.1.0.0/16"
subnet_cidrs = {
  app_gateway = "10.1.1.0/24"
  aks         = "10.1.10.0/24"
  database    = "10.1.20.0/24"
  gateway     = "10.1.30.0/24"
}

# AKS Configuration (Warm Standby)
enable_warm_standby = false  # Set to true for active-active DR
aks_vm_size        = "Standard_D2s_v3"
aks_max_nodes      = 10

# Database Configuration
postgres_version   = "15"
postgres_sku      = "GP_Standard_D2s_v3"
postgres_storage_mb = 32768  # 32 GB

# Monitoring Configuration
log_retention_days = 90

# Notification Endpoints
notification_endpoints = [
  "platform-team@company.com",
  "security-team@company.com",
  "finops-team@company.com"
]

# Cross-Cloud VPN Configuration
enable_cross_cloud_vpn = false  # Set to true to enable AWS-Azure VPN
# aws_vpn_gateway_ip    = ""     # Set when enabling VPN
# vpn_shared_key        = ""     # Set via environment variable

# DR Configuration
dr_config = {
  rto_minutes              = 15
  rpo_minutes              = 5
  cross_region_replication = true
  backup_retention_days    = 30
}