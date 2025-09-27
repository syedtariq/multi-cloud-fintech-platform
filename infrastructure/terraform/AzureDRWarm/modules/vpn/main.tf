# Azure VPN Module - Cross-Cloud Connectivity

resource "azurerm_public_ip" "vpn" {
  name                = "${var.name_prefix}-vpn-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                = "Standard"

  tags = var.common_tags
}

resource "azurerm_virtual_network_gateway" "main" {
  name                = "${var.name_prefix}-vpn-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  tags = var.common_tags
}

resource "azurerm_local_network_gateway" "aws" {
  name                = "${var.name_prefix}-aws-local-gateway"
  resource_group_name = var.resource_group_name
  location            = var.location
  gateway_address     = var.aws_vpn_gateway_ip
  address_space       = ["10.0.0.0/16"]

  tags = var.common_tags
}

resource "azurerm_virtual_network_gateway_connection" "aws" {
  name                = "${var.name_prefix}-aws-connection"
  location            = var.location
  resource_group_name = var.resource_group_name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws.id
  shared_key                 = var.shared_key

  tags = var.common_tags
}