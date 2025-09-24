# Global Resources
# CloudFront, Route 53 Global DNS, Cross-Region Routing

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
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

# Default provider (us-east-1 for global resources)
provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "FinTech-Trading-Platform"
      Environment = "production"
      Scope       = "Global"
      Owner       = "Platform-Team"
      CostCenter  = "Engineering"
      Compliance  = "SOC2-PCI-GDPR"
    }
  }
}

# EU provider for data sources
provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}

# Data sources for regional resources
data "terraform_remote_state" "us_prod" {
  backend = "s3"
  config = {
    bucket = "fintech-platform-terraform-state"
    key    = "us-prod/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "eu_prod" {
  count = var.enable_eu_region ? 1 : 0
  backend = "s3"
  config = {
    bucket = "fintech-platform-terraform-state"
    key    = "eu-prod/terraform.tfstate"
    region = "us-east-1"
  }
}

# Local Values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "production"
    Scope       = "Global"
    ManagedBy   = "Terraform"
    Owner       = "Platform-Team"
  }
}

# Route 53 Hosted Zone (Global)
resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = local.common_tags
}

# Global CloudFront Distribution for Static Assets
resource "aws_cloudfront_distribution" "global_static" {
  origin {
    domain_name = data.terraform_remote_state.us_prod.outputs.s3_bucket_domain_name
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

# Route 53 Geolocation Routing for API
resource "aws_route53_record" "api_eu_users" {
  count   = var.enable_eu_region ? 1 : 0
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = "EU-API"
  
  geolocation_routing_policy {
    continent = "EU"
  }

  alias {
    name                   = data.terraform_remote_state.eu_prod[0].outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.eu_prod[0].outputs.alb_zone_id
    evaluate_target_health = true
  }
}

# Default API routing for non-EU users
resource "aws_route53_record" "api_default_users" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = "DEFAULT-API"
  
  geolocation_routing_policy {
    country = "*"  # Default for all other countries
  }

  alias {
    name                   = data.terraform_remote_state.us_prod.outputs.alb_dns_name
    zone_id                = data.terraform_remote_state.us_prod.outputs.alb_zone_id
    evaluate_target_health = true
  }
}

# Static Assets Route (Global CloudFront)
resource "aws_route53_record" "static_assets" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "static.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.global_static.domain_name
    zone_id                = "Z2FDTNDATAQYW2"  # CloudFront hosted zone ID
    evaluate_target_health = false
  }
}

# Health Checks for Failover
resource "aws_route53_health_check" "us_api" {
  fqdn                            = "api.${var.domain_name}"
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = 3
  request_interval                = 30
  
  tags = merge(local.common_tags, {
    Name = "US-API-Health-Check"
  })
}

resource "aws_route53_health_check" "eu_api" {
  count = var.enable_eu_region ? 1 : 0
  
  fqdn                            = "eu.api.${var.domain_name}"
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = 3
  request_interval                = 30
  
  tags = merge(local.common_tags, {
    Name = "EU-API-Health-Check"
  })
}