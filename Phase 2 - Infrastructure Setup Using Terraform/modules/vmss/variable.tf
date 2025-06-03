variable "vmss_name" {
  description = "Name of the VMSS"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "vm_size" {
  description = "VM size for the scale set"
  type        = string
}

variable "instance_count" {
  description = "Number of VM instances"
  type        = number
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for the VMSS"
  type        = string
}

variable "backend_pool_id" {
  description = "ID of the load balancer backend pool"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
