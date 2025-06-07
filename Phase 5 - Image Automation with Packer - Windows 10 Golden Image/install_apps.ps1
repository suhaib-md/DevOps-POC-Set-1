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
