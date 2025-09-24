variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "fintech-trading-platform"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "enable_eu_region" {
  description = "Enable EU region resources"
  type        = bool
  default     = false
}