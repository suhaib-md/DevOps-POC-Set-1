output "vnet_id" {
  description = "ID of the VNET"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Name of the VNET"
  value       = azurerm_virtual_network.vnet.name
}
