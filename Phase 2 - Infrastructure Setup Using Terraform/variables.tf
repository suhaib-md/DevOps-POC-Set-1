variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "aks-multi-az-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "aks-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the VNET"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Map of subnet names to address prefixes"
  type        = map(object({
    address_prefix = string
  }))
  default = {
    "aks"        = { address_prefix = "10.0.1.0/24" }
    "appgateway" = { address_prefix = "10.0.2.0/24" }
    "vmss"       = { address_prefix = "10.0.3.0/24" }
  }
}

variable "nsg_name" {
  description = "Name of the NSG"
  type        = string
  default     = "aks-nsg"
}

# REMOVED: Route table variables - not needed with loadBalancer outbound type

variable "nat_gateway_name" {
  description = "Name of the NAT Gateway"
  type        = string
  default     = "aks-nat-gateway"
}

variable "app_gateway_name" {
  description = "Name of the Application Gateway"
  type        = string
  default     = "aks-app-gateway"
}

variable "lb_name" {
  description = "Name of the Load Balancer"
  type        = string
  default     = "aks-load-balancer"
}

variable "vmss_name" {
  description = "Name of the VMSS"
  type        = string
  default     = "aks-vmss"
}

variable "vm_size" {
  description = "VM size for the scale set"
  type        = string
  default     = "Standard_B1s"
}

variable "instance_count" {
  description = "Number of VM instances"
  type        = number
  default     = 1
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "aks_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "aks_vm_size" {
  description = "VM size for the AKS node pool"
  type        = string
  default     = "Standard_B1s"
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default = {
    environment = "development"
    project     = "aks-multi-az"
  }
}
