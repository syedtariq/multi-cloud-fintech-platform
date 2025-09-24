variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for DMS resources"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for DMS"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "Private route table IDs for VPN routes"
  type        = list(string)
}

variable "rds_cluster_endpoint" {
  description = "RDS cluster endpoint"
  type        = string
}

variable "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  type        = string
}

variable "enable_azure_dr" {
  description = "Enable Azure disaster recovery"
  type        = bool
  default     = false
}

variable "azure_vpn_gateway_ip" {
  description = "Azure VPN Gateway public IP"
  type        = string
  default     = ""
}

variable "azure_postgres_fqdn" {
  description = "Azure PostgreSQL FQDN"
  type        = string
  default     = ""
}

variable "azure_postgres_password" {
  description = "Azure PostgreSQL password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "azure_redis_hostname" {
  description = "Azure Redis hostname"
  type        = string
  default     = ""
}

variable "azure_redis_key" {
  description = "Azure Redis access key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}