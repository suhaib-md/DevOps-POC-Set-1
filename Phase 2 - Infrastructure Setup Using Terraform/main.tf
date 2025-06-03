# Simplified main.tf - Root Module for Student Subscription
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create Resource Group first
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create VNET
module "vnet" {
  source              = "./modules/vnet"
  vnet_name           = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  
  depends_on = [azurerm_resource_group.rg]
}

# Create Subnets
module "subnets" {
  source              = "./modules/subnets"
  subnets             = var.subnets
  resource_group_name = azurerm_resource_group.rg.name
  vnet_name           = module.vnet.vnet_name
  
  depends_on = [module.vnet]
}

# Create NSG with simplified rules
module "nsg" {
  source              = "./modules/nsg"
  nsg_name            = var.nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  
  depends_on = [azurerm_resource_group.rg]
}

# Create NAT Gateway
#module "nat_gateway" {
 # source              = "./modules/nat_gateway"
  #nat_gateway_name    = var.nat_gateway_name
  #location            = var.location
  #resource_group_name = azurerm_resource_group.rg.name
  #tags                = var.tags
  
  #depends_on = [azurerm_resource_group.rg]
#}

# Create Load Balancer
module "load_balancer" {
  source              = "./modules/load_balancer"
  lb_name             = var.lb_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
  
  depends_on = [azurerm_resource_group.rg]
}

# REMOVED: Route Table module - Not needed with loadBalancer outbound type

# Wait for all core networking resources
resource "time_sleep" "wait_for_core_networking" {
  depends_on = [
    module.vnet,
    module.subnets,
    module.nsg,
    module.load_balancer
  ]
  create_duration = "30s"  # Reduced wait time
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "aks_nsg" {
  subnet_id                 = module.subnets.subnet_ids["aks"]
  network_security_group_id = module.nsg.nsg_id
  
  depends_on = [time_sleep.wait_for_core_networking]
}

resource "azurerm_subnet_network_security_group_association" "vmss_nsg" {
  subnet_id                 = module.subnets.subnet_ids["vmss"]
  network_security_group_id = module.nsg.nsg_id
  
  depends_on = [time_sleep.wait_for_core_networking]
}

resource "azurerm_subnet_network_security_group_association" "appgw_nsg" {
  subnet_id                 = module.subnets.subnet_ids["appgateway"]
  network_security_group_id = module.nsg.nsg_id
  
  depends_on = [time_sleep.wait_for_core_networking]
}

# NAT Gateway Associations
#resource "azurerm_subnet_nat_gateway_association" "aks_nat" {
  #subnet_id      = module.subnets.subnet_ids["aks"]
  #nat_gateway_id = module.nat_gateway.nat_gateway_id
  
  #depends_on = [time_sleep.wait_for_core_networking]
#}

#resource "azurerm_subnet_nat_gateway_association" "vmss_nat" {
  #subnet_id      = module.subnets.subnet_ids["vmss"]
  #nat_gateway_id = module.nat_gateway.nat_gateway_id
  
  #depends_on = [time_sleep.wait_for_core_networking]
#}

# Wait for associations
resource "time_sleep" "wait_for_associations" {
  depends_on = [
    azurerm_subnet_network_security_group_association.aks_nsg,
    azurerm_subnet_network_security_group_association.vmss_nsg,
    azurerm_subnet_network_security_group_association.appgw_nsg
    #azurerm_subnet_nat_gateway_association.aks_nat,
    #azurerm_subnet_nat_gateway_association.vmss_nat
  ]
  create_duration = "30s"
}

# Create Application Gateway
module "app_gateway" {
  source              = "./modules/app_gateway"
  app_gateway_name    = var.app_gateway_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.subnets.subnet_ids["appgateway"]
  tags                = var.tags
  
  depends_on = [time_sleep.wait_for_associations]
}

# Create VMSS
module "vmss" {
  source              = "./modules/vmss"
  vmss_name           = var.vmss_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  vm_size             = var.vm_size
  instance_count      = var.instance_count
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  subnet_id           = module.subnets.subnet_ids["vmss"]
  backend_pool_id     = module.load_balancer.backend_pool_id
  tags                = var.tags
  
  depends_on = [time_sleep.wait_for_associations]
}

# Create AKS - Now with simplified networking
module "aks" {
  source              = "./modules/aks"
  aks_name            = var.aks_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  kubernetes_version  = var.kubernetes_version
  node_count          = var.node_count
  vm_size             = var.aks_vm_size
  subnet_id           = module.subnets.subnet_ids["aks"]
  tags                = var.tags
  
  depends_on = [time_sleep.wait_for_associations]
}
