variable "subnets" {
  description = "Map of subnet names to address prefixes"
  type        = map(object({
    address_prefix = string
  }))
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}
