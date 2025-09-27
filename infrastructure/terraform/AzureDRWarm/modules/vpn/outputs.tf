output "vpn_gateway_public_ip" {
  description = "Public IP of the VPN Gateway"
  value       = azurerm_public_ip.vpn.ip_address
}

output "connection_status" {
  description = "Status of the VPN connection"
  value       = azurerm_virtual_network_gateway_connection.aws.connection_status
}