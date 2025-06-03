# modules/route_table/main.tf - Fixed with proper subnet association
resource "azurerm_route_table" "route_table" {
  name                = var.route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  
  # Use the new property name instead of deprecated one
  bgp_route_propagation_enabled = true
}

resource "azurerm_route" "routes" {
  for_each               = var.routes
  name                   = each.key
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.route_table.name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address != null ? each.value.next_hop_in_ip_address : null
}

# Associate route table with AKS subnet - This is critical for AKS with userDefinedRouting
resource "azurerm_subnet_route_table_association" "aks" {
  count          = var.associate_with_subnets ? 1 : 0
  subnet_id      = var.aks_subnet_id
  route_table_id = azurerm_route_table.route_table.id
  
  depends_on = [
    azurerm_route_table.route_table,
    azurerm_route.routes
  ]
}
