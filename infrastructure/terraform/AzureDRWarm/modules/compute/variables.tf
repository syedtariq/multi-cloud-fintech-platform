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

variable "vnet_id" {
  description = "ID of the Virtual Network"
  type        = string
}

variable "subnet_id" {
  description = "ID of the AKS subnet"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "max_node_count" {
  description = "Maximum number of nodes"
  type        = number
  default     = 10
}

variable "common_tags" {
  description = "Common tags for resources"
  type        = map(string)
}