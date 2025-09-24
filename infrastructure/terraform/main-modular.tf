# Modular Main Configuration
# Multi-Cloud Financial Services Platform

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
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_primary_region
  
  default_tags {
    tags = {
      Project     = "FinTech-Trading-Platform"
      Environment = var.environment
      Owner       = "Platform-Team"
      CostCenter  = "Engineering"
      Compliance  = "SOC2-PCI-GDPR"
    }
  }
}

# Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Local Values
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Platform-Team"
  }

  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  name_prefix        = local.name_prefix
  vpc_cidr          = "10.0.0.0/16"
  azs               = local.azs
  public_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets   = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  database_subnets  = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
  common_tags       = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  name_prefix = local.name_prefix
  vpc_id      = module.networking.vpc_id
  common_tags = local.common_tags
}

# Database Module
module "database" {
  source = "./modules/database"

  name_prefix         = local.name_prefix
  vpc_id              = module.networking.vpc_id
  database_subnet_ids = module.networking.database_subnet_ids
  security_group_ids  = [module.security.database_sg_id]
  kms_key_arn        = module.security.database_kms_key_arn
  common_tags        = local.common_tags
}

# Compute Module (EKS)
module "compute" {
  source = "./modules/compute"

  name_prefix         = local.name_prefix
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  public_subnet_ids   = module.networking.public_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  cluster_sg_id       = module.security.eks_cluster_sg_id
  nodes_sg_id         = module.security.eks_nodes_sg_id
  cluster_role_arn    = module.security.eks_cluster_role_arn
  nodes_role_arn      = module.security.eks_nodes_role_arn
  kms_key_arn        = module.security.cluster_kms_key_arn
  common_tags        = local.common_tags
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api-gateway"

  name_prefix   = local.name_prefix
  domain_name   = var.domain_name
  alb_arn       = module.compute.alb_arn
  alb_dns_name  = module.compute.alb_dns_name
  common_tags   = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix            = local.name_prefix
  eks_cluster_name       = module.compute.eks_cluster_name
  kms_key_arn           = module.security.cluster_kms_key_arn
  notification_endpoints = var.notification_endpoints
  common_tags           = local.common_tags
}