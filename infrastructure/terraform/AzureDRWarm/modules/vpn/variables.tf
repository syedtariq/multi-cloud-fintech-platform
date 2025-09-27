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

variable "gateway_subnet_id" {
  description = "ID of the gateway subnet"
  type        = string
}

variable "aws_vpn_gateway_ip" {
  description = "AWS VPN Gateway public IP"
  type        = string
}

variable "shared_key" {
  description = "Shared key for VPN connection"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Common tags for resources"
  type        = map(string)
}