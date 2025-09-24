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

# AWS Provider - US Region (Primary)
provider "aws" {
  alias  = "us"
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

# AWS Provider - EU Region (GDPR Compliance)
provider "aws" {
  alias  = "eu"
  region = var.aws_eu_region
  
  default_tags {
    tags = {
      Project     = "FinTech-Trading-Platform"
      Environment = var.environment
      Owner       = "Platform-Team"
      CostCenter  = "Engineering"
      Compliance  = "SOC2-PCI-GDPR"
      Region      = "EU"
    }
  }
}

# Default provider for global resources
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
  provider = aws.us
  state    = "available"
}

data "aws_availability_zones" "eu_available" {
  provider = aws.eu
  state    = "available"
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

  azs    = slice(data.aws_availability_zones.available.names, 0, 3)
  eu_azs = slice(data.aws_availability_zones.eu_available.names, 0, 3)
}

# US Networking Module
module "us_networking" {
  source = "./modules/networking"
  
  providers = {
    aws = aws.us
  }

  name_prefix        = "${local.name_prefix}-us"
  vpc_cidr          = "10.0.0.0/16"
  azs               = local.azs
  public_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets   = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  database_subnets  = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
  common_tags       = merge(local.common_tags, { Region = "US" })
}

# EU Networking Module (GDPR Compliance)
module "eu_networking" {
  count  = var.enable_eu_region ? 1 : 0
  source = "./modules/networking"
  
  providers = {
    aws = aws.eu
  }

  name_prefix        = "${local.name_prefix}-eu"
  vpc_cidr          = "10.1.0.0/16"
  azs               = local.eu_azs
  public_subnets    = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnets   = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
  database_subnets  = ["10.1.20.0/24", "10.1.21.0/24", "10.1.22.0/24"]
  common_tags       = merge(local.common_tags, { Region = "EU", GDPR = "Compliant" })
}

# US Security Module
module "us_security" {
  source = "./modules/security"
  
  providers = {
    aws = aws.us
  }

  name_prefix = "${local.name_prefix}-us"
  vpc_id      = module.us_networking.vpc_id
  domain_name = var.domain_name
  common_tags = merge(local.common_tags, { Region = "US" })
}

# EU Security Module
module "eu_security" {
  count  = var.enable_eu_region ? 1 : 0
  source = "./modules/security"
  
  providers = {
    aws = aws.eu
  }

  name_prefix = "${local.name_prefix}-eu"
  vpc_id      = module.eu_networking[0].vpc_id
  domain_name = "eu.${var.domain_name}"
  common_tags = merge(local.common_tags, { Region = "EU", GDPR = "Compliant" })
}

# US Database Module
module "us_database" {
  source = "./modules/database"
  
  providers = {
    aws = aws.us
  }

  name_prefix         = "${local.name_prefix}-us"
  vpc_id              = module.us_networking.vpc_id
  database_subnet_ids = module.us_networking.database_subnet_ids
  security_group_ids  = [module.us_security.database_sg_id]
  kms_key_arn        = module.us_security.database_kms_key_arn
  common_tags        = merge(local.common_tags, { Region = "US" })
}

# EU Database Module (GDPR Compliant)
module "eu_database" {
  count  = var.enable_eu_region ? 1 : 0
  source = "./modules/database"
  
  providers = {
    aws = aws.eu
  }

  name_prefix         = "${local.name_prefix}-eu"
  vpc_id              = module.eu_networking[0].vpc_id
  database_subnet_ids = module.eu_networking[0].database_subnet_ids
  security_group_ids  = [module.eu_security[0].database_sg_id]
  kms_key_arn        = module.eu_security[0].database_kms_key_arn
  common_tags        = merge(local.common_tags, { Region = "EU", GDPR = "Compliant" })
}

# US Compute Module (EKS)
module "us_compute" {
  source = "./modules/compute"
  
  providers = {
    aws = aws.us
  }

  name_prefix                   = "${local.name_prefix}-us"
  vpc_id                        = module.us_networking.vpc_id
  private_subnet_ids            = module.us_networking.private_subnet_ids
  public_subnet_ids             = module.us_networking.public_subnet_ids
  alb_sg_id                    = module.us_security.alb_sg_id
  cluster_sg_id                 = module.us_security.eks_cluster_sg_id
  nodes_sg_id                   = module.us_security.eks_nodes_sg_id
  cluster_role_arn              = module.us_security.eks_cluster_role_arn
  nodes_role_arn                = module.us_security.eks_nodes_role_arn
  kms_key_arn                  = module.us_security.cluster_kms_key_arn
  ssl_certificate_arn           = module.us_api_gateway.ssl_certificate_arn
  cognito_user_pool_arn         = module.us_security.cognito_user_pool_arn
  cognito_user_pool_client_id   = module.us_security.cognito_user_pool_client_id
  cognito_user_pool_domain      = module.us_security.cognito_user_pool_domain
  common_tags                  = merge(local.common_tags, { Region = "US" })
}

# EU Compute Module (EKS)
module "eu_compute" {
  count  = var.enable_eu_region ? 1 : 0
  source = "./modules/compute"
  
  providers = {
    aws = aws.eu
  }

  name_prefix                   = "${local.name_prefix}-eu"
  vpc_id                        = module.eu_networking[0].vpc_id
  private_subnet_ids            = module.eu_networking[0].private_subnet_ids
  public_subnet_ids             = module.eu_networking[0].public_subnet_ids
  alb_sg_id                    = module.eu_security[0].alb_sg_id
  cluster_sg_id                 = module.eu_security[0].eks_cluster_sg_id
  nodes_sg_id                   = module.eu_security[0].eks_nodes_sg_id
  cluster_role_arn              = module.eu_security[0].eks_cluster_role_arn
  nodes_role_arn                = module.eu_security[0].eks_nodes_role_arn
  kms_key_arn                  = module.eu_security[0].cluster_kms_key_arn
  ssl_certificate_arn           = module.eu_api_gateway[0].ssl_certificate_arn
  cognito_user_pool_arn         = module.eu_security[0].cognito_user_pool_arn
  cognito_user_pool_client_id   = module.eu_security[0].cognito_user_pool_client_id
  cognito_user_pool_domain      = module.eu_security[0].cognito_user_pool_domain
  common_tags                  = merge(local.common_tags, { Region = "EU", GDPR = "Compliant" })
}

# US API Gateway Module
module "us_api_gateway" {
  source = "./modules/api-gateway"

  name_prefix   = "${local.name_prefix}-us"
  domain_name   = var.domain_name
  alb_arn       = module.us_compute.alb_arn
  alb_dns_name  = module.us_compute.alb_dns_name
  common_tags   = merge(local.common_tags, { Region = "US" })
}

# EU API Gateway Module
module "eu_api_gateway" {
  count  = var.enable_eu_region ? 1 : 0
  source = "./modules/api-gateway"
  
  providers = {
    aws = aws.eu
  }

  name_prefix   = "${local.name_prefix}-eu"
  domain_name   = "eu.${var.domain_name}"
  alb_arn       = module.eu_compute[0].alb_arn
  alb_dns_name  = module.eu_compute[0].alb_dns_name
  common_tags   = merge(local.common_tags, { Region = "EU", GDPR = "Compliant" })
}

# US Monitoring Module
module "us_monitoring" {
  source = "./modules/monitoring"
  
  providers = {
    aws = aws.us
  }

  name_prefix            = "${local.name_prefix}-us"
  eks_cluster_name       = module.us_compute.eks_cluster_name
  kms_key_arn           = module.us_security.cluster_kms_key_arn
  notification_endpoints = var.notification_endpoints
  common_tags           = merge(local.common_tags, { Region = "US" })
}

# EU Monitoring Module
module "eu_monitoring" {
  count  = var.enable_eu_region ? 1 : 0
  source = "./modules/monitoring"
  
  providers = {
    aws = aws.eu
  }

  name_prefix            = "${local.name_prefix}-eu"
  eks_cluster_name       = module.eu_compute[0].eks_cluster_name
  kms_key_arn           = module.eu_security[0].cluster_kms_key_arn
  notification_endpoints = var.notification_endpoints
  common_tags           = merge(local.common_tags, { Region = "EU", GDPR = "Compliant" })
}

# Global CloudFront for Static Assets (Single Distribution)
resource "aws_cloudfront_distribution" "global_static" {
  origin {
    domain_name = module.us_database.s3_bucket_domain_name
    origin_id   = "S3-Static-Assets"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.static_assets.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"
  
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-Static-Assets"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}

resource "aws_cloudfront_origin_access_identity" "static_assets" {
  comment = "OAI for static assets"
}

# Route 53 API Geolocation Routing (Direct to ALBs)
resource "aws_route53_record" "api_eu_users" {
  count   = var.enable_eu_region ? 1 : 0
  zone_id = module.us_api_gateway.route53_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = "EU-API"
  
  geolocation_routing_policy {
    continent = "EU"
  }

  alias {
    name                   = module.eu_compute[0].alb_dns_name
    zone_id                = module.eu_compute[0].alb_zone_id
    evaluate_target_health = true
  }
}

# Default API routing for non-EU users
resource "aws_route53_record" "api_default_users" {
  zone_id = module.us_api_gateway.route53_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = "DEFAULT-API"
  
  geolocation_routing_policy {
    country = "*"  # Default for all other countries
  }

  alias {
    name                   = module.us_compute.alb_dns_name
    zone_id                = module.us_compute.alb_zone_id
    evaluate_target_health = true
  }
}

# Static Assets Route (Global CloudFront)
resource "aws_route53_record" "static_assets" {
  zone_id = module.us_api_gateway.route53_zone_id
  name    = "static.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.global_static.domain_name
    zone_id                = "Z2FDTNDATAQYW2"  # CloudFront hosted zone ID
    evaluate_target_health = false
  }
}