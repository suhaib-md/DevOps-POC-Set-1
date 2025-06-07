# Packer configuration for Windows 10 golden image in Azure
packer {
  required_plugins {
    azure = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

variable "client_id" {
  type      = string
  sensitive = true
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "tenant_id" {
  type      = string
  sensitive = true
}

variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "resource_group" {
  type    = string
  default = "myPackerGroup"
}

variable "location" {
  type    = string
  default = "eastus"
}

locals {
  timestamp = regex_replace(timestamp(), "[: TZ-]", "")
}

source "azure-arm" "windows-10" {
  client_id                         = var.client_id
  client_secret                     = var.client_secret
  tenant_id                         = var.tenant_id
  subscription_id                   = var.subscription_id
  managed_image_resource_group_name = var.resource_group
  managed_image_name                = "windows-10-golden-${local.timestamp}"
  location                          = var.location
  vm_size                           = "Standard_D2s_v3"
  os_type                           = "Windows"
  image_publisher                   = "MicrosoftWindowsDesktop"
  image_offer                       = "Windows-10"
  image_sku                         = "20h2-ent"
  communicator                      = "winrm"
  winrm_use_ssl                     = true
  winrm_insecure                    = true
  winrm_timeout                     = "30m"
  winrm_username                    = "packer"
  winrm_password                    = "SuperS3cr3t!!!!"
}

build {
  name    = "windows-10-golden"
  sources = ["source.azure-arm.windows-10"]

  # Configure WinRM and install PSWindowsUpdate
  provisioner "powershell" {
    inline = [
      "Write-Host 'Configuring WinRM...'",
      "winrm quickconfig -q",
      "winrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"1024\"}'",
      "winrm set winrm/config '@{MaxTimeoutms=\"1800000\"}'",
      "winrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'",
      "winrm set winrm/config/service/auth '@{Basic=\"true\"}'",
      "netsh advfirewall firewall add rule name=\"WinRM 5985\" protocol=TCP dir=in localport=5985 action=allow",
      "net user packer SuperS3cr3t!!!! /add /y",
      "net localgroup administrators packer /add",
      "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force",
      "Install-Module -Name PSWindowsUpdate -Force"
    ]
  }

  # Install Windows Updates
  provisioner "powershell" {
    inline = [
      "Write-Host 'Installing Windows Updates...'",
      "$ErrorActionPreference = 'Stop'",
      "Install-WindowsUpdate -AcceptAll -AutoReboot"
    ]
  }

  # Restart Windows after updates
  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  # Install sample applications (Notepad++, 7Zip, and Chrome)
  provisioner "powershell" {
    script = "./install_apps.ps1"
  }

  # Configure system settings
  provisioner "powershell" {
    script = "./configure_system.ps1"
  }

  # Final cleanup and sysprep preparation
  provisioner "powershell" {
    inline = [
      "Write-Host 'Final cleanup and preparation for sysprep...'",
      "# Stop Windows Update service",
      "Stop-Service -Name 'wuauserv' -Force -ErrorAction SilentlyContinue",
      "Set-Service -Name 'wuauserv' -StartupType Disabled",
      "# Clear temp files",
      "Get-ChildItem -Path 'C:\\Windows\\Temp' -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue",
      "Get-ChildItem -Path 'C:\\Users\\*\\AppData\\Local\\Temp' -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue",
      "# Clear event logs",
      "Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue }",
      "# Remove packer user (optional)",
      "# net user packer /delete",
      "Write-Host 'Cleanup completed. Ready for sysprep.'"
    ]
  }

  # Sysprep (correct and blocking)
  provisioner "powershell" {
    inline = [
      "C:\\Windows\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /shutdown /quiet"
    ]
  }
}
