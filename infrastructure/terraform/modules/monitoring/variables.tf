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