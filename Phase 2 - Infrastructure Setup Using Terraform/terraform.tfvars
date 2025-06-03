resource_group_name = "aks-multi-az-rg"
location            = "East US"
vnet_name           = "aks-vnet"
vnet_address_space  = ["10.0.0.0/16"]

subnets = {
  "aks"        = { address_prefix = "10.0.1.0/24" }
  "appgateway" = { address_prefix = "10.0.2.0/24" }
  "vmss"       = { address_prefix = "10.0.3.0/24" }
}

nsg_name = "aks-nsg"

# REMOVED: Route table variables - not needed with loadBalancer outbound type

nat_gateway_name = "aks-nat-gateway"
app_gateway_name = "aks-app-gateway"
lb_name          = "aks-load-balancer"
vmss_name        = "aks-vmss"

# Student subscription friendly VM sizes
vm_size          = "Standard_B2ms"
instance_count   = 1
admin_username   = "azureuser"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

aks_name           = "aks-cluster"
kubernetes_version = "1.32.4"  # Stable version

node_count         = 1
aks_vm_size        = "Standard_B2ms"

tags = {
  environment = "development"
  project     = "aks-multi-az"
  owner       = "student"
}
