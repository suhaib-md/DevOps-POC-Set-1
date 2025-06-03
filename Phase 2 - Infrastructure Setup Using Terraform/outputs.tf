output "vnet_id" {
  description = "ID of the VNET"
  value       = module.vnet.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = module.subnets.subnet_ids
}

output "nsg_id" {
  description = "ID of the NSG"
  value       = module.nsg.nsg_id
}

# REMOVED: Route table output - not needed with loadBalancer outbound type

#output "nat_gateway_id" {
  #description = "ID of the NAT Gateway"
  #value       = module.nat_gateway.nat_gateway_id
#}

output "app_gateway_id" {
  description = "ID of the Application Gateway"
  value       = module.app_gateway.app_gateway_id
}

output "lb_id" {
  description = "ID of the Load Balancer"
  value       = module.load_balancer.lb_id
}

output "vmss_id" {
  description = "ID of the VMSS"
  value       = module.vmss.vmss_id
}

output "aks_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.aks_id
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.aks_fqdn
}
