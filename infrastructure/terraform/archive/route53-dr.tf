# Route 53 Disaster Recovery Configuration
# Multi-Cloud Failover: AWS Primary → Azure DR

# Health Check for AWS Primary ALB
resource "aws_route53_health_check" "aws_primary" {
  fqdn                            = module.us_compute.alb_dns_name
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = 3
  request_interval                = 30
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aws-primary-health"
    Type = "Primary"
  })
}

# Health Check for AWS EU Region
resource "aws_route53_health_check" "aws_eu" {
  count = var.enable_eu_region ? 1 : 0
  
  fqdn                            = module.eu_compute[0].alb_dns_name
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = 3
  request_interval                = 30
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aws-eu-health"
    Type = "Secondary"
  })
}

# Health Check for Azure DR (External)
resource "aws_route53_health_check" "azure_dr" {
  count = var.enable_azure_dr ? 1 : 0
  
  fqdn                            = var.azure_app_gateway_fqdn
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = 3
  request_interval                = 30
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-azure-dr-health"
    Type = "DisasterRecovery"
  })
}

# Primary Record - AWS US (Weighted + Health Check)
resource "aws_route53_record" "primary" {
  zone_id = module.us_api_gateway.route53_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60

  weighted_routing_policy {
    weight = 100
  }
  
  set_identifier  = "AWS-PRIMARY"
  health_check_id = aws_route53_health_check.aws_primary.id

  alias {
    name                   = module.us_compute.alb_dns_name
    zone_id                = module.us_compute.alb_zone_id
    evaluate_target_health = true
  }
}

# Secondary Record - AWS EU (Weighted + Health Check)
resource "aws_route53_record" "secondary" {
  count   = var.enable_eu_region ? 1 : 0
  zone_id = module.us_api_gateway.route53_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60

  weighted_routing_policy {
    weight = 50
  }
  
  set_identifier  = "AWS-EU-SECONDARY"
  health_check_id = aws_route53_health_check.aws_eu[0].id

  alias {
    name                   = module.eu_compute[0].alb_dns_name
    zone_id                = module.eu_compute[0].alb_zone_id
    evaluate_target_health = true
  }
}

# Disaster Recovery Record - Azure (Failover)
resource "aws_route53_record" "disaster_recovery" {
  count   = var.enable_azure_dr ? 1 : 0
  zone_id = module.us_api_gateway.route53_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60

  failover_routing_policy {
    type = "SECONDARY"
  }
  
  set_identifier = "AZURE-DR"
  records        = [var.azure_app_gateway_ip]
}

# API Subdomain - Multi-tier Failover
resource "aws_route53_record" "api_primary" {
  zone_id = module.us_api_gateway.route53_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = 30

  failover_routing_policy {
    type = "PRIMARY"
  }
  
  set_identifier  = "API-PRIMARY"
  health_check_id = aws_route53_health_check.aws_primary.id

  alias {
    name                   = module.us_compute.alb_dns_name
    zone_id                = module.us_compute.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api_secondary" {
  count   = var.enable_eu_region ? 1 : 0
  zone_id = module.us_api_gateway.route53_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = 30

  failover_routing_policy {
    type = "SECONDARY"
  }
  
  set_identifier  = "API-EU-SECONDARY"
  health_check_id = var.enable_eu_region ? aws_route53_health_check.aws_eu[0].id : null

  alias {
    name                   = module.eu_compute[0].alb_dns_name
    zone_id                = module.eu_compute[0].alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api_dr" {
  count   = var.enable_azure_dr ? 1 : 0
  zone_id = module.us_api_gateway.route53_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  ttl     = 30

  failover_routing_policy {
    type = "SECONDARY"
  }
  
  set_identifier = "API-AZURE-DR"
  records        = [var.azure_app_gateway_ip]
}