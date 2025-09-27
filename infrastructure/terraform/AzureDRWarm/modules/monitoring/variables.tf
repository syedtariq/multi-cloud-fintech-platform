variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 90
}

variable "alert_emails" {
  description = "Email addresses for alerts"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags for resources"
  type        = map(string)
}