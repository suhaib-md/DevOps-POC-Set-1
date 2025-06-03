# modules/subnets/main.tf
resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [each.value.address_prefix]
  
  # Service endpoints for AKS and Application Gateway
  service_endpoints = each.key == "aks" ? ["Microsoft.Storage", "Microsoft.KeyVault"] : (
    each.key == "appgateway" ? ["Microsoft.Web"] : []
  )
  
  # Remove delegation block - Application Gateway doesn't require subnet delegation
  # Application Gateway can be deployed to any subnet without special delegation
}
