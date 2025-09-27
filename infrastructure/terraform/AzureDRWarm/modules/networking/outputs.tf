output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "app_gateway_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = azurerm_subnet.app_gateway.id
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "database_subnet_id" {
  description = "ID of the database subnet"
  value       = azurerm_subnet.database.id
}

output "gateway_subnet_id" {
  description = "ID of the gateway subnet"
  value       = azurerm_subnet.gateway.id
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value = {
    app_gateway = azurerm_subnet.app_gateway.id
    aks         = azurerm_subnet.aks.id
    database    = azurerm_subnet.database.id
    gateway     = azurerm_subnet.gateway.id
  }
}