# Azure DR Outputs
# Multi-Cloud Financial Services Platform - Disaster Recovery

# Resource Group
output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the Azure resource group"
  value       = azurerm_resource_group.main.location
}

# Networking
output "vnet_id" {
  description = "ID of the Azure Virtual Network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the Azure Virtual Network"
  value       = module.networking.vnet_name
}

output "subnet_ids" {
  description = "IDs of the Azure subnets"
  value       = module.networking.subnet_ids
}

# AKS Cluster
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.compute.aks_cluster_name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.compute.aks_cluster_id
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.compute.aks_cluster_fqdn
}

output "aks_node_resource_group" {
  description = "Resource group of AKS nodes"
  value       = module.compute.aks_node_resource_group
}

# Database
output "postgres_server_name" {
  description = "Name of the PostgreSQL server"
  value       = module.database.postgres_server_name
}

output "postgres_server_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = module.database.postgres_server_fqdn
}

output "redis_cache_name" {
  description = "Name of the Redis cache"
  value       = module.database.redis_cache_name
}

output "redis_cache_hostname" {
  description = "Hostname of the Redis cache"
  value       = module.database.redis_cache_hostname
}

# Application Gateway
output "app_gateway_public_ip" {
  description = "Public IP of the Application Gateway"
  value       = module.app_gateway.public_ip_address
}

output "app_gateway_fqdn" {
  description = "FQDN of the Application Gateway"
  value       = module.app_gateway.fqdn
}

# Storage
output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.database.storage_account_name
}

output "storage_account_primary_endpoint" {
  description = "Primary endpoint of the storage account"
  value       = module.database.storage_account_primary_endpoint
}

# Monitoring
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = module.monitoring.application_insights_instrumentation_key
  sensitive   = true
}

# VPN (if enabled)
output "vpn_gateway_public_ip" {
  description = "Public IP of the VPN Gateway"
  value       = var.enable_cross_cloud_vpn ? module.vpn[0].vpn_gateway_public_ip : null
}

output "vpn_connection_status" {
  description = "Status of the VPN connection"
  value       = var.enable_cross_cloud_vpn ? module.vpn[0].connection_status : "Not configured"
}

# DR Summary
output "dr_summary" {
  description = "Summary of Azure DR deployment"
  value = {
    # Infrastructure
    resource_group = azurerm_resource_group.main.name
    location      = azurerm_resource_group.main.location
    vnet_cidr     = var.vnet_cidr
    
    # Compute
    aks_cluster   = module.compute.aks_cluster_name
    node_count    = var.enable_warm_standby ? 3 : 1
    vm_size       = var.aks_vm_size
    
    # Database
    postgres_server = module.database.postgres_server_name
    redis_cache    = module.database.redis_cache_name
    
    # Networking
    app_gateway_ip = module.app_gateway.public_ip_address
    vpn_enabled   = var.enable_cross_cloud_vpn
    
    # DR Configuration
    rto_minutes   = var.dr_config.rto_minutes
    rpo_minutes   = var.dr_config.rpo_minutes
    warm_standby  = var.enable_warm_standby
    
    # Endpoints
    api_endpoint     = "https://${module.app_gateway.fqdn}"
    database_endpoint = module.database.postgres_server_fqdn
    cache_endpoint   = module.database.redis_cache_hostname
  }
}