<powershell>
# Enable error handling
$ErrorActionPreference = "Stop"
Start-Transcript -Path C:\Windows\Temp\userdata.log

try {
    # Configure static IP
    Write-Host "Configuring static IP..."
    $NetworkAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    $CurrentIP = Get-NetIPAddress -InterfaceIndex $NetworkAdapter.ifIndex -AddressFamily IPv4
    
    # Get current network configuration
    $CurrentNetIPConfig = Get-NetIPConfiguration -InterfaceIndex $NetworkAdapter.ifIndex
    $Gateway = $CurrentNetIPConfig.IPv4DefaultGateway.NextHop
    
    Write-Host "Current Network Configuration:"
    Write-Host "IP Address: $($CurrentIP.IPAddress)"
    Write-Host "Prefix Length: $($CurrentIP.PrefixLength)"
    Write-Host "Gateway: $Gateway"

    # Only proceed with static IP configuration if we have all required information
    if ($CurrentIP -and $Gateway) {
        Write-Host "Setting static IP configuration..."
        
        # Remove existing IP configuration
        Remove-NetIPAddress -InterfaceIndex $NetworkAdapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceIndex $NetworkAdapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue

        # Set static IP
        $null = New-NetIPAddress -InterfaceIndex $NetworkAdapter.ifIndex `
            -AddressFamily IPv4 `
            -IPAddress $CurrentIP.IPAddress `
            -PrefixLength $CurrentIP.PrefixLength `
            -DefaultGateway $Gateway

        Write-Host "Static IP configuration completed."
    } else {
        Write-Host "Warning: Could not get complete network information. Keeping DHCP configuration."
    }

    # Set DNS to localhost (required for AD DS)
    Set-DnsClientServerAddress -InterfaceIndex $NetworkAdapter.ifIndex -ServerAddresses "127.0.0.1"

    # Configure RDP before AD DS installation
    Write-Host "Configuring RDP access..."
    
    # Enable RDP
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1
    
    # Configure Windows Firewall for RDP
    Write-Host "Configuring Windows Firewall for RDP..."
    
    # Enable RDP in Windows Firewall
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
    
    # If the above fails, create new rules
    $RDPRules = @(
        @{Name="RemoteDesktop-UserMode-In-TCP"; Protocol="TCP"; LocalPort="3389"},
        @{Name="RemoteDesktop-UserMode-In-UDP"; Protocol="UDP"; LocalPort="3389"}
    )

    foreach ($Rule in $RDPRules) {
        if (!(Get-NetFirewallRule -DisplayName $Rule.Name -ErrorAction SilentlyContinue)) {
            Write-Host "Creating firewall rule: $($Rule.Name)"
            New-NetFirewallRule -DisplayName $Rule.Name `
                -Direction Inbound `
                -Protocol $Rule.Protocol `
                -LocalPort $Rule.LocalPort `
                -Action Allow `
                -Profile Any `
                -Group "Remote Desktop" `
                -Enabled True
        }
    }

    # Enable CredSSP
    Enable-WSManCredSSP -Role Server -Force

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

        # Create scheduled task to re-enable RDP after reboot
        Write-Host "Creating scheduled task for RDP persistence..."
        $Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -Command "Set-ItemProperty -Path \"HKLM:\System\CurrentControlSet\Control\Terminal Server\" -Name \"fDenyTSConnections\" -Value 0; Enable-NetFirewallRule -DisplayGroup \"Remote Desktop\""'
        $Trigger = New-ScheduledTaskTrigger -AtStartup
        $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        Register-ScheduledTask -TaskName "ReEnableRDP" -Action $Action -Trigger $Trigger -Principal $Principal -Force

        Write-Host "Promoting to Domain Controller..."
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

    Write-Host "Setup completed. System will restart."
} catch {
    Write-Host "Error occurred: $_"
    Write-Host "Stack Trace: $($_.ScriptStackTrace)"
    throw
} finally {
    Stop-Transcript
}

# Create a flag file to indicate first boot is complete
New-Item -Path C:\Windows\Temp\FirstBootComplete -ItemType File -Force

# Restart system
Restart-Computer -Force
</powershell>
