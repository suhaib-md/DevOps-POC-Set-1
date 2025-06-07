# Phase 5: Image Automation with Packer - Windows 10 Golden Image

## 🎯 Overview

This project automates the creation of Windows 10 golden images using HashiCorp Packer in Microsoft Azure. The solution creates standardized, pre-configured VM images with essential applications and security updates, enabling rapid deployment of consistent Windows environments.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Project Structure](#project-structure)
- [Configuration Files](#configuration-files)
- [PowerShell Scripts](#powershell-scripts)
- [WinRM Setup](#winrm-setup)
- [Packer Usage](#packer-usage)
- [Image Verification](#image-verification)
- [Deployment & Testing](#deployment--testing)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## 🔧 Prerequisites

### System Requirements

| Component | Requirement |
|-----------|-------------|
| Operating System | Windows 10/11 with WSL2 or Linux distribution |
| Memory | Minimum 8GB RAM (16GB recommended) |
| Storage | 50GB free disk space |
| Network | Stable internet connection for Azure operations |

### Required Tools & Services

| Tool | Version | Purpose |
|------|---------|---------|
| HashiCorp Packer | Latest | Image building automation |
| Azure CLI | 2.0+ | Azure resource management |
| PowerShell | 5.1+ | Windows configuration scripts |
| WSL2 Debian | Latest | Linux subsystem for Windows |
| Azure Subscription | Active | Cloud infrastructure |

### Required Permissions

- **Azure Subscription**: Contributor role
- **Resource Group**: Full access to create/manage resources
- **Compute**: VM creation and management permissions
- **Storage**: Disk and image management access

## 🚀 Environment Setup

### Step 1: Install Packer on WSL Debian

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required dependencies
sudo apt install -y wget unzip curl gnupg lsb-release

# Add HashiCorp GPG key and repository
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Packer
sudo apt-get update && sudo apt-get install packer

# Verify installation
packer version
```

### Step 2: Install Azure CLI

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Verify login and list subscriptions
az account list --output table
```

### Step 3: Create Azure Service Principal

```bash
# Create service principal for Packer
az ad sp create-for-rbac --name "PackerPrincipal" --role Contributor --scope /subscriptions/YOUR_SUBSCRIPTION_ID

# Create resource group
az group create --name myPackerGroup --location eastus
```

**Expected Output:**
```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "PackerPrincipal",
  "password": "your-generated-password",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

⚠️ **Important**: Save these credentials securely - they'll be needed for the Packer configuration.

## 📁 Project Structure

Create the following directory structure for your Packer project:

```
windows10-packer/
├── README.md
├── windows.pkr.hcl          # Main Packer template
├── vars.json                # Sensitive variables (add to .gitignore)
├── install-apps.ps1         # Application installation script
├── configure-system.ps1     # System configuration script
└── .gitignore              # Git ignore file
```

### Create Project Directory

```bash
mkdir -p windows10-packer/
cd windows10-packer
```

## ⚙️ Configuration Files

### Main Packer Template (windows.pkr.hcl)

```hcl
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
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "azure-arm" "windows-10" {
  client_id                         = var.client_id
  client_secret                     = var.client_secret
  tenant_id                         = var.tenant_id
  subscription_id                   = var.subscription_id
  
  managed_image_resource_group_name = var.resource_group
  managed_image_name                = "windows-10-golden-${local.timestamp}"
  
  location = var.location
  vm_size  = "Standard_D2s_v3"
  
  os_type         = "Windows"
  image_publisher = "MicrosoftWindowsDesktop"
  image_offer     = "Windows-10"
  image_sku       = "20h2-ent"
  
  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "30m"
  winrm_username = "packer"
  winrm_password = "SuperS3cr3t!!!!"
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
    script = "./install-apps.ps1"
  }

  # Configure system settings
  provisioner "powershell" {
    script = "./configure-system.ps1"
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
```

### Variables File (vars.json)

```json
{
  "client_id": "your-service-principal-app-id",
  "client_secret": "your-service-principal-password",
  "tenant_id": "your-azure-tenant-id",
  "subscription_id": "your-azure-subscription-id"
}
```

⚠️ **Security Note**: Add `vars.json` to your `.gitignore` file to prevent credential exposure.

### Git Ignore File (.gitignore)

```gitignore
# Sensitive files
vars.json
*.log
packer-debug.log

# Temporary files
*.tmp
*.temp
packer_cache/

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
```

## 🔨 PowerShell Scripts

### Application Installation Script (install-apps.ps1)

```powershell
# Install sample applications
$ErrorActionPreference = 'Stop'
Write-Host 'Installing sample applications...'

try {
    # Create temp directory
    New-Item -ItemType Directory -Path 'C:\Temp' -Force

    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Install Notepad++, 7Zip, and Chrome
    choco install notepadplusplus 7zip googlechrome -y

    Write-Host 'Applications installed successfully'
}
catch {
    Write-Host "Error during application installation: $($_.Exception.Message)"
    throw
}
finally {
    # Clean up
    Remove-Item -Path 'C:\Temp' -Recurse -Force -ErrorAction SilentlyContinue
}
```

### System Configuration Script (configure-system.ps1)

```powershell
# Configure system settings
$ErrorActionPreference = 'Stop'
Write-Host 'Configuring system settings...'

try {
    # Set timezone
    Set-TimeZone -Id 'Eastern Standard Time'
    Write-Host 'Timezone set to Eastern Standard Time'

    # Disable Windows Defender real-time monitoring (optional, for performance)
    try {
        Set-MpPreference -DisableRealtimeMonitoring $true
        Write-Host 'Windows Defender real-time monitoring disabled'
    }
    catch {
        Write-Host 'Could not disable Windows Defender - continuing...'
    }

    # Set power plan to High Performance
    try {
        powercfg /setactive SCHEME_MIN
        Write-Host 'Power plan set to High Performance'
    }
    catch {
        Write-Host 'Could not set power plan - continuing...'
    }

    # Disable UAC (optional, for automation)
    try {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -Value 0
        Write-Host 'UAC disabled'
    }
    catch {
        Write-Host 'Could not disable UAC - continuing...'
    }

    Write-Host 'System configuration completed successfully'
}
catch {
    Write-Host "Error during system configuration: $($_.Exception.Message)"
    throw
}
```

## 🔗 WinRM Setup

WinRM (Windows Remote Management) is automatically configured by the Packer template. Here's what happens during the build process:

### Automatic WinRM Configuration

1. **Service Configuration**: WinRM service is configured with extended timeouts and memory limits
2. **Authentication Setup**: Basic authentication is enabled for the build process
3. **Firewall Rules**: Port 5985 is opened for WinRM communication
4. **User Creation**: A temporary `packer` user is created with administrator privileges

### Manual WinRM Verification (if needed)

```powershell
# Check WinRM configuration
winrm get winrm/config

# Test WinRM connectivity
Test-WSMan -ComputerName localhost

# Enable WinRM (if needed)
winrm quickconfig -q
```

### WinRM Troubleshooting

If WinRM connection fails:

```powershell
# Check service status
Get-Service WinRM

# Restart WinRM service
Restart-Service WinRM

# Check firewall rules
netsh advfirewall firewall show rule name="WinRM 5985"
```

## 🚀 Packer Usage

### Step 1: Prepare Environment

```bash
# Navigate to project directory
cd windows10-packer

# Initialize Packer (downloads required plugins)
packer init windows.pkr.hcl

# Validate the Packer template
packer validate -var-file="vars.json" windows.pkr.hcl
```

### Step 2: Execute Image Build

```bash
# Build the golden image
packer build -var-file="vars.json" windows.pkr.hcl
```

### Step 3: Monitor Build Progress

```bash
# Enable debug logging (optional)
export PACKER_LOG=1
export PACKER_LOG_PATH="packer-debug.log"

# Run build with debugging
packer build -var-file="vars.json" windows.pkr.hcl
```

### Expected Build Process Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| VM Creation | 5-10 min | Azure VM provisioning |
| WinRM Setup | 2-5 min | Windows Remote Management configuration |
| Windows Updates | 15-30 min | System updates installation |
| App Installation | 10-15 min | Chocolatey and applications |
| System Config | 5-10 min | Settings and optimizations |
| Cleanup & Sysprep | 5-10 min | Final preparation |
| **Total** | **45-80 min** | Complete build process |

## ✅ Image Verification

### Step 1: Verify Built Image

```bash
# List all custom images in resource group
az image list --resource-group myPackerGroup --output table

# Get detailed image information
az image show --resource-group myPackerGroup \
  --name windows-10-golden-TIMESTAMP \
  --output json
```

### Step 2: Check Image Properties

```bash
# Verify image specifications
az image show --resource-group myPackerGroup \
  --name windows-10-golden-20250607000903 \
  --query '{Name:name, Location:location, OsType:storageProfile.osDisk.osType, Size:storageProfile.osDisk.diskSizeGb, State:provisioningState}' \
  --output table
```

**Expected Output:**
```
Name                           Location    OsType    Size    State
-----------------------------  ----------  --------  ------  ---------
windows-10-golden-20250607...  eastus      Windows   127     Succeeded
```

### Step 3: Image Validation Checklist

- ✅ Image creation completed successfully
- ✅ Image size is appropriate (typically 127GB)
- ✅ Provisioning state shows "Succeeded"
- ✅ OS type is correctly identified as "Windows"

## 🚀 Deployment & Testing

### Create Test VM from Golden Image

#### Step 1: Create Network Infrastructure

```bash
# Create virtual network
az network vnet create \
  --resource-group myPackerGroup \
  --name myVNet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name mySubnet \
  --subnet-prefix 10.0.1.0/24

# Create network security group
az network nsg create \
  --resource-group myPackerGroup \
  --name myNetworkSecurityGroup

# Add RDP rule
az network nsg rule create \
  --resource-group myPackerGroup \
  --nsg-name myNetworkSecurityGroup \
  --name AllowRDP \
  --protocol tcp \
  --priority 1000 \
  --destination-port-range 3389 \
  --access allow

# Create public IP
az network public-ip create \
  --resource-group myPackerGroup \
  --name myPublicIP \
  --allocation-method Static

# Create network interface
az network nic create \
  --resource-group myPackerGroup \
  --name myNic \
  --vnet-name myVNet \
  --subnet mySubnet \
  --public-ip-address myPublicIP \
  --network-security-group myNetworkSecurityGroup
```

#### Step 2: Deploy VM from Golden Image

```bash
# Create VM from golden image
az vm create \
  --resource-group myPackerGroup \
  --name myWindowsVM \
  --image windows-10-golden-TIMESTAMP \
  --admin-username azureuser \
  --admin-password 'YourSecurePassword123!' \
  --nics myNic \
  --size Standard_D2s_v3 \
  --storage-sku Premium_LRS

# Get public IP for connection
az vm show \
  --resource-group myPackerGroup \
  --name myWindowsVM \
  --show-details \
  --query publicIps \
  --output tsv
```

### Connection Methods

#### Option 1: Windows RDP Client

1. Open Remote Desktop Connection
2. Enter the public IP address
3. Username: `azureuser`
4. Password: `YourSecurePassword123!`

#### Option 2: Linux/WSL RDP Client

```bash
# Install FreeRDP
sudo apt install freerdp2-x11

# Connect to VM
xfreerdp /v:YOUR_PUBLIC_IP /u:azureuser /p:'YourSecurePassword123!' /size:1920x1080
```

### Verification Checklist

Once connected to your VM, verify the following components:

#### ✅ Check Installed Applications
- [ ] Notepad++ is installed
- [ ] 7Zip is installed
- [ ] Google Chrome is installed
- [ ] Check Start Menu → All Apps

#### ✅ Check System Configuration
- [ ] Timezone is set to Eastern Standard Time
- [ ] Power plan is set to High Performance
- [ ] Windows Defender settings (if disabled)
- [ ] UAC settings (if disabled)

#### ✅ Check Windows Updates
- [ ] Go to Settings → Update & Security → Windows Update
- [ ] Verify updates are installed

## 🔧 Troubleshooting

### Common Issues and Solutions

#### WinRM Connection Failures

**Problem**: Packer cannot connect via WinRM
**Error**: `timeout waiting for WinRM connection`

**Solutions**:
- Verify firewall rules allow port 5985
- Check WinRM service status: `winrm get winrm/config`
- Ensure proper authentication settings
- Increase `winrm_timeout` in template

#### Azure Authentication Errors

**Problem**: Service principal authentication fails
**Error**: `azure-arm builder error: authentication failure`

**Solutions**:
- Verify service principal credentials in `vars.json`
- Check service principal permissions: `az role assignment list --assignee YOUR_CLIENT_ID`
- Ensure subscription ID is correct
- Regenerate service principal if needed

#### PowerShell Script Execution Failures

**Problem**: Scripts fail with execution policy errors
**Error**: `execution of scripts is disabled on this system`

**Solutions**:
- Add execution policy bypass to scripts: `Set-ExecutionPolicy Bypass -Scope Process -Force`
- Use inline PowerShell commands instead of script files
- Check script syntax and error handling

#### Chocolatey Installation Issues

**Problem**: Package installation fails
**Error**: `The remote name could not be resolved: 'chocolatey.org'`

**Solutions**:
- Ensure internet connectivity during build
- Set TLS 1.2 protocol: `[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12`
- Use alternative package sources
- Install packages individually with error handling

#### Sysprep Failures

**Problem**: Sysprep process fails or hangs
**Error**: `sysprep failed with exit code 1`

**Solutions**:
- Check sysprep logs: `C:\Windows\System32\Sysprep\Panther\`
- Remove user profiles before sysprep
- Ensure no pending reboots
- Disable Windows Store updates during build

### Debug Mode Execution

For detailed troubleshooting, enable debug logging:

```bash
# Enable debug output
export PACKER_LOG=1
export PACKER_LOG_PATH="packer-debug.log"

# Run build with debugging
packer build -var-file="vars.json" windows.pkr.hcl
```

### Resource Cleanup

If build fails, clean up Azure resources:

```bash
# List resource groups
az group list --output table

# Delete resource group (removes all resources)
az group delete --name myPackerGroup --yes --no-wait

# Or delete specific resources
az vm delete --resource-group myPackerGroup --name packer-build-vm --yes
az disk delete --resource-group myPackerGroup --name packer-build-disk --yes
```

## 📚 Best Practices

### Security Best Practices

#### Credential Management
- Use Azure Key Vault for sensitive variables
- Rotate service principal credentials regularly
- Never commit credentials to version control
- Use environment variables for CI/CD pipelines

#### Network Security
- Use private subnets for build process
- Implement least-privilege network access
- Configure NSG rules to restrict RDP/WinRM access
- Use Azure Bastion for secure remote access

#### Image Security
- Keep base images updated with latest patches
- Remove unnecessary services and features
- Implement proper antivirus exclusions
- Configure Windows Defender appropriately

### Performance Optimization

#### Build Performance
- Use SSD storage for build VMs
- Select appropriate VM sizes (Standard_D2s_v3 minimum)
- Parallel provisioning where possible
- Cache frequently downloaded packages

#### Image Optimization
- Remove temporary files and caches
- Optimize disk usage before sysprep
- Configure services for optimal startup
- Implement proper power management settings

### Automation Best Practices

#### Template Design
- Use variables for all configurable parameters
- Implement proper error handling in scripts
- Create modular, reusable components
- Document all customizations

#### Version Control
- Tag releases with semantic versioning
- Maintain changelog for image versions
- Use branching strategy for different environments
- Implement automated testing

## 📖 Additional Resources

### Documentation Links
- [HashiCorp Packer Documentation](https://www.packer.io/docs)
- [Azure ARM Builder](https://www.packer.io/docs/builders/azure/arm)
- [PowerShell DSC with Packer](https://www.packer.io/docs/provisioners/powershell)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)

### Community Resources
- [Packer Community Forum](https://discuss.hashicorp.com/c/packer)
- [Azure DevOps Extensions](https://marketplace.visualstudio.com/search?term=packer&target=AzureDevOps)
- [GitHub Packer Templates](https://github.com/topics/packer-template)

---

## 📋 Deliverables Summary

This project provides the following deliverables:

1. **windows.pkr.hcl** - Main Packer template for Windows 10 golden image
2. **install-apps.ps1** - PowerShell script for application installation
3. **configure-system.ps1** - PowerShell script for system configuration
4. **vars.json** - Variables file for sensitive configuration
5. **README.md** - This comprehensive documentation
6. **.gitignore** - Git ignore file for security

## 📝 Document Information

- **Document Version**: 1.0
- **Last Updated**: June 2025
- **Author**: Infrastructure Automation Team
- **Review Date**: Quarterly

This documentation is maintained as a living document and should be updated regularly to reflect changes in requirements, procedures, and best practices.