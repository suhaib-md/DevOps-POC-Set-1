# Fixed modules/aks/main.tf - Remove userDefinedRouting for student subscription
# Log Analytics Workspace for AKS monitoring - Create this first
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "${var.aks_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.aks_name}-dns"
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags
  
  # Enable RBAC
  role_based_access_control_enabled = true
  
  # Enable local accounts for student subscription
  local_account_disabled = false

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.vm_size
    enable_auto_scaling = true
    min_count           = var.node_count
    max_count           = var.node_count + 1  # Reduced for student subscription
    vnet_subnet_id      = var.subnet_id
    type                = "VirtualMachineScaleSets"
    os_disk_size_gb     = 30
    os_disk_type        = "Managed"
    
    # Node labels for system pool
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = "development"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # SIMPLIFIED network profile - Remove userDefinedRouting for student subscription
  network_profile {
    network_plugin      = "azure"
    network_policy      = "azure"
    load_balancer_sku   = "standard"
    # CHANGED: Use loadBalancer instead of userDefinedRouting
    outbound_type       = "loadBalancer"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
  }
  
  # Enable monitoring with explicit dependency
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }
  
  # Add explicit dependency
  depends_on = [
    azurerm_log_analytics_workspace.aks
  ]
}
