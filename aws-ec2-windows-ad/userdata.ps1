<powershell>
# Enable error handling
$ErrorActionPreference = "Stop"
Start-Transcript -Path C:\Windows\Temp\userdata.log

try {
    if ("${install_adds}" -eq "true") {
        Write-Host "Starting Active Directory Domain Services installation..."
        
        # Install AD DS role
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
        Install-WindowsFeature -Name DNS -IncludeManagementTools

        # Configure AD domain
        $domainName = "${domain_name}"
        $NetBIOSName = "${domain_netbios_name}"

        # Set admin password
        $AdminPassword = ConvertTo-SecureString "${domain_admin_password}" -AsPlainText -Force
        $AdminCred = New-Object System.Management.Automation.PSCredential ("Administrator", $AdminPassword)

        # Promote to Domain Controller
        Install-ADDSForest `
            -DomainName $domainName `
            -DomainNetbiosName $NetBIOSName `
            -SafeModeAdministratorPassword $AdminPassword `
            -InstallDns `
            -Force `
            -NoRebootOnCompletion

        Write-Host "Active Directory Domain Services installation completed."
    } else {
        Write-Host "Skipping AD DS installation as install_adds is not true"
    }

    # Enable RDP
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

    # Allow RDP through Windows Firewall
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    Write-Host "Setup completed. System will restart."
} catch {
    Write-Host "Error occurred: $_"
    throw
} finally {
    Stop-Transcript
}

# Restart system
Restart-Computer -Force
</powershell>
