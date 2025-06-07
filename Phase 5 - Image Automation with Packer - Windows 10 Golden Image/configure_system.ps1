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
