# API Gateway Module - REST API, VPC Link, Custom Domain

# API Gateway REST API
resource "aws_api_gateway_rest_api" "trading_api" {
  name = "${var.name_prefix}-trading-api"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.common_tags
}

# API Gateway VPC Link
resource "aws_api_gateway_vpc_link" "trading_vpc_link" {
  name        = "${var.name_prefix}-vpc-link"
  target_arns = [var.alb_arn]

  tags = var.common_tags
}

# API Gateway Integration
resource "aws_api_gateway_integration" "trading_integration" {
  rest_api_id = aws_api_gateway_rest_api.trading_api.id
  resource_id = aws_api_gateway_rest_api.trading_api.root_resource_id
  http_method = "ANY"
  
  integration_http_method = "ANY"
  type                   = "HTTP_PROXY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_api_gateway_vpc_link.trading_vpc_link.id
  uri                    = "http://${var.alb_dns_name}/{proxy}"
}

# API Gateway Method
resource "aws_api_gateway_method" "trading_method" {
  rest_api_id   = aws_api_gateway_rest_api.trading_api.id
  resource_id   = aws_api_gateway_rest_api.trading_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "trading_deployment" {
  depends_on = [
    aws_api_gateway_method.trading_method,
    aws_api_gateway_integration.trading_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.trading_api.id
  stage_name  = "prod"

  lifecycle {
    create_before_destroy = true
  }
}

# ACM Certificate for API Gateway
resource "aws_acm_certificate" "api_cert" {
  domain_name       = "api.${var.domain_name}"
  validation_method = "DNS"

  tags = var.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Custom Domain
resource "aws_api_gateway_domain_name" "trading_domain" {
  domain_name     = "api.${var.domain_name}"
  certificate_arn = aws_acm_certificate.api_cert.arn

  tags = var.common_tags
}

# API Gateway Base Path Mapping
resource "aws_api_gateway_base_path_mapping" "trading_mapping" {
  api_id      = aws_api_gateway_rest_api.trading_api.id
  stage_name  = aws_api_gateway_deployment.trading_deployment.stage_name
  domain_name = aws_api_gateway_domain_name.trading_domain.domain_name
}

# Route 53 Record for API Gateway
resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = var.common_tags
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.trading_domain.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.trading_domain.cloudfront_zone_id
    evaluate_target_health = true
  }
}

# Route 53 Health Check for API Gateway
resource "aws_route53_health_check" "api_health" {
  fqdn                            = "api.${var.domain_name}"
  port                            = 443
  type                            = "HTTPS"
  resource_path                   = "/health"
  failure_threshold               = 3
  request_interval                = 30
  
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-api-health-check"
  })
}