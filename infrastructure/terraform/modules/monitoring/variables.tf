variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for log encryption"
  type        = string
}

variable "notification_endpoints" {
  description = "List of email endpoints for alerts"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "monitoring_config" {
  description = "Monitoring configuration"
  type = object({
    enable_detailed_monitoring = bool
    log_retention_days        = number
    create_dashboards         = bool
    alert_thresholds = object({
      cpu_utilization    = number
      memory_utilization = number
      disk_utilization   = number
      api_latency_ms     = number
      error_rate_percent = number
    })
  })
}