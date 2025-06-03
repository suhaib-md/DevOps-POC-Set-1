output "lb_id" {
  description = "ID of the Load Balancer"
  value       = azurerm_lb.load_balancer.id
}

output "backend_pool_id" {
  description = "ID of the backend address pool"
  value       = azurerm_lb_backend_address_pool.backend_pool.id
}
