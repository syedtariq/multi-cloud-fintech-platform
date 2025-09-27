output "public_ip_address" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.main.ip_address
}

output "fqdn" {
  description = "FQDN of the Application Gateway"
  value       = azurerm_public_ip.main.fqdn
}

output "app_gateway_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}