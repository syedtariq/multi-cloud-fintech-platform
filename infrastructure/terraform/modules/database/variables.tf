variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "database_subnet_ids" {
  description = "Database subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for database access"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "azure_blob_endpoint" {
  description = "Azure Blob Storage endpoint for S3 replication"
  type        = string
  default     = "azure-trading-data-blob"
}

variable "azure_postgres_endpoint" {
  description = "Azure PostgreSQL endpoint for DMS replication"
  type        = string
  default     = "azure-postgres.database.azure.com"
}

variable "azure_redis_endpoint" {
  description = "Azure Redis endpoint for sync"
  type        = string
  default     = "azure-redis.redis.cache.windows.net"
}

variable "database_config" {
  description = "Database configuration"
  type = object({
    engine_version          = string
    instance_class         = string
    allocated_storage      = number
    max_allocated_storage  = number
    backup_retention_days  = number
    multi_az              = bool
    performance_insights  = bool
  })
}

variable "cache_config" {
  description = "Cache configuration"
  type = object({
    engine_version     = string
    node_type         = string
    num_cache_nodes   = number
    parameter_group   = string
  })
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}