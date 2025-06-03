# modules/nat_gateway/main.tf - Fixed version
resource "azurerm_public_ip" "nat_ip" {
  name                = "${var.nat_gateway_name}-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["3"]  # Specify zone for consistency
  tags                = var.tags
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                    = var.nat_gateway_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["3"]  # Specify zone for consistency
  tags                    = var.tags

  depends_on = [
    azurerm_public_ip.nat_ip
  ]
}

resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_ip.id

  depends_on = [
    azurerm_nat_gateway.nat_gateway,
    azurerm_public_ip.nat_ip
  ]
}
