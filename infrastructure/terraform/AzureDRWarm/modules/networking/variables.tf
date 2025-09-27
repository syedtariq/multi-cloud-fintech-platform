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

variable "vnet_cidr" {
  description = "CIDR block for VNet"
  type        = string
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type = object({
    app_gateway = string
    aks         = string
    database    = string
    gateway     = string
  })
}

variable "common_tags" {
  description = "Common tags for resources"
  type        = map(string)
}