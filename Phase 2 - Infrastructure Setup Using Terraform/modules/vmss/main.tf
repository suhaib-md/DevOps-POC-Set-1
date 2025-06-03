# Fixed modules/vmss/main.tf - Remove zones to avoid allocation issues
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_size
  instances           = var.instance_count
  admin_username      = var.admin_username
  tags                = var.tags
  
  # Disable password authentication
  disable_password_authentication = true
  
  # Remove zones to avoid allocation issues - let Azure choose best placement
  # zones = ["3"]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.vmss_name}-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      subnet_id                              = var.subnet_id
      primary                                = true
      load_balancer_backend_address_pool_ids = var.backend_pool_id != null ? [var.backend_pool_id] : []
    }
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }
  
  # Custom script extension for basic setup
  extension {
    name                 = "HealthExtension"
    publisher            = "Microsoft.ManagedServices"
    type                 = "ApplicationHealthLinux"
    type_handler_version = "1.0"
    settings = jsonencode({
      protocol    = "http"
      port        = 80
      requestPath = "/"
    })
  }
}
