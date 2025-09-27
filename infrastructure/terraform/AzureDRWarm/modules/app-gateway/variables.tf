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
  description = "ID of the Application Gateway subnet"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

variable "common_tags" {
  description = "Common tags for resources"
  type        = map(string)
}