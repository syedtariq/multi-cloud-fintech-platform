# Azure DR Main Configuration
# Multi-Cloud Financial Services Platform - Disaster Recovery

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "fintech-platform-terraform-state"
    storage_account_name = "fintechterraformstate"
    container_name       = "tfstate"
    key                  = "azure-dr/terraform.tfstate"
  }
}

# Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

# Local Values
locals {
  name_prefix = "${var.project_name}-${var.environment}-dr"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Platform-Team"
    Purpose     = "DisasterRecovery"
    Region      = "EastUS2"
  }
}

# Azure Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.azure_location

  tags = local.common_tags
}

# Azure Networking Module
module "networking" {
  source = "./modules/networking"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  vnet_cidr          = var.vnet_cidr
  subnet_cidrs       = var.subnet_cidrs
  common_tags        = local.common_tags
}

# Azure Security Module
module "security" {
  source = "./modules/security"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  vnet_id            = module.networking.vnet_id
  subnet_ids         = module.networking.subnet_ids
  common_tags        = local.common_tags
}

# Azure Compute Module (AKS)
module "compute" {
  source = "./modules/compute"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  vnet_id            = module.networking.vnet_id
  subnet_id          = module.networking.aks_subnet_id
  common_tags        = local.common_tags
  
  # Warm standby configuration
  node_count         = var.enable_warm_standby ? 3 : 1
  vm_size           = var.aks_vm_size
  max_node_count    = var.aks_max_nodes
}

# Azure Database Module
module "database" {
  source = "./modules/database"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  vnet_id            = module.networking.vnet_id
  database_subnet_id  = module.networking.database_subnet_id
  common_tags        = local.common_tags
  
  # Database configuration
  postgres_version    = var.postgres_version
  postgres_sku        = var.postgres_sku
  storage_mb         = var.postgres_storage_mb
}

# Azure Application Gateway Module
module "app_gateway" {
  source = "./modules/app-gateway"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  vnet_id            = module.networking.vnet_id
  subnet_id          = module.networking.app_gateway_subnet_id
  common_tags        = local.common_tags
  
  domain_name        = var.domain_name
}

# Azure Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  common_tags        = local.common_tags
  
  # Monitoring configuration
  log_retention_days = var.log_retention_days
  alert_emails      = var.notification_endpoints
}

# Cross-Cloud VPN Connection (conditional)
module "vpn" {
  count  = var.enable_cross_cloud_vpn ? 1 : 0
  source = "./modules/vpn"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  vnet_id            = module.networking.vnet_id
  gateway_subnet_id   = module.networking.gateway_subnet_id
  common_tags        = local.common_tags
  
  # AWS VPN configuration
  aws_vpn_gateway_ip = var.aws_vpn_gateway_ip
  shared_key        = var.vpn_shared_key
}