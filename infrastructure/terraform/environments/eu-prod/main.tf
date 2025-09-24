# EU Production Environment
# Financial Trading Platform - EU Region (GDPR Compliant)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "fintech-platform-terraform-state"
    key            = "eu-prod/terraform.tfstate"
    region         = "us-east-1"  # State bucket in US, but resources in EU
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "FinTech-Trading-Platform"
      Environment = "production"
      Region      = "EU"
      Owner       = "Platform-Team"
      CostCenter  = "Engineering"
      Compliance  = "SOC2-PCI-GDPR"
      GDPR        = "Compliant"
    }
  }
}

# Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Local Values
locals {
  name_prefix = "${var.project_name}-${var.environment}-eu"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Region      = "EU"
    ManagedBy   = "Terraform"
    Owner       = "Platform-Team"
    GDPR        = "Compliant"
  }

  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  name_prefix        = local.name_prefix
  vpc_cidr          = var.vpc_cidr
  azs               = local.azs
  public_subnets    = var.public_subnets
  private_subnets   = var.private_subnets
  database_subnets  = var.database_subnets
  common_tags       = local.common_tags
}

# Security Module
module "security" {
  source = "../../modules/security"

  name_prefix = local.name_prefix
  vpc_id      = module.networking.vpc_id
  domain_name = var.domain_name
  common_tags = local.common_tags
}

# Database Module
module "database" {
  source = "../../modules/database"

  name_prefix         = local.name_prefix
  vpc_id              = module.networking.vpc_id
  database_subnet_ids = module.networking.database_subnet_ids
  security_group_ids  = [module.security.database_sg_id]
  kms_key_arn        = module.security.database_kms_key_arn
  database_config    = var.database_config
  cache_config       = var.cache_config
  rds_password       = var.rds_password
  common_tags        = local.common_tags
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  name_prefix                   = local.name_prefix
  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = module.networking.private_subnet_ids
  public_subnet_ids             = module.networking.public_subnet_ids
  alb_sg_id                    = module.security.alb_sg_id
  cluster_sg_id                 = module.security.eks_cluster_sg_id
  nodes_sg_id                   = module.security.eks_nodes_sg_id
  cluster_role_arn              = module.security.eks_cluster_role_arn
  nodes_role_arn                = module.security.eks_nodes_role_arn
  kms_key_arn                  = module.security.cluster_kms_key_arn
  ssl_certificate_arn           = module.api_gateway.ssl_certificate_arn
  cognito_user_pool_arn         = module.security.cognito_user_pool_arn
  cognito_user_pool_client_id   = module.security.cognito_user_pool_client_id
  cognito_user_pool_domain      = module.security.cognito_user_pool_domain
  eks_config                   = var.eks_config
  common_tags                  = local.common_tags
}

# API Gateway Module
module "api_gateway" {
  source = "../../modules/api-gateway"

  name_prefix   = local.name_prefix
  domain_name   = var.domain_name
  alb_arn       = module.compute.alb_arn
  alb_dns_name  = module.compute.alb_dns_name
  common_tags   = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix            = local.name_prefix
  eks_cluster_name       = module.compute.eks_cluster_name
  kms_key_arn           = module.security.cluster_kms_key_arn
  notification_endpoints = var.notification_endpoints
  monitoring_config     = var.monitoring_config
  common_tags           = local.common_tags
}