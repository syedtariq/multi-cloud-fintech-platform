variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the API"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}