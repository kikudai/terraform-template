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

    # Disable Network Level Authentication (NLA)
    (Get-WmiObject -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0)

    # タイムゾーンの設定
    Write-Host "Configuring timezone settings..."
    try {
        # タイムゾーンを東京に設定
        Set-TimeZone -Id "Tokyo Standard Time"
        
        # 初期時刻同期の設定
        # AWSのタイムサーバーと同期
        w32tm /config /syncfromflags:manual /manualpeerlist:"169.254.169.123" /update
        Restart-Service w32time
        w32tm /resync /force
        
        # 同期完了まで待機
        Start-Sleep -Seconds 10
        
        Write-Host "Current time settings:"
        w32tm /query /status
        Get-Date
        
        Write-Host "Timezone and time sync configuration completed."
    } catch {
        Write-Host "Error configuring timezone settings: $_"
        Write-Host "Stack Trace: $($_.ScriptStackTrace)"
    }

    if ("${install_adds}" -eq "true") {
        Write-Host "Starting Active Directory Domain Services installation..."
        
        # Install AD DS role
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
        Install-WindowsFeature -Name DNS -IncludeManagementTools

        # DNS設定の確認と構成
        Write-Host "Configuring DNS Server..."
        try {
            # DNSサーバーの設定
            $dnsServer = Get-DnsServer
            if ($dnsServer) {
                # 逆引きゾーンの作成
                $networkId = $CurrentIP.IPAddress -replace "\.\d+$", ""
                Add-DnsServerPrimaryZone -NetworkID "$networkId.0/24" -ReplicationScope "Forest"

                # フォワーダーの設定
                Set-DnsServerForwarder -IPAddress "169.254.169.253" -UseRootHint $false

                # DNSサーバーの再起動
                Restart-Service DNS

                # DNSレコードの登録を確認
                $zoneName = "${domain_name}"
                $computerName = $env:COMPUTERNAME
                $aRecord = Get-DnsServerResourceRecord -ZoneName $zoneName -Name $computerName -RRType A -ErrorAction SilentlyContinue
                
                if (-not $aRecord) {
                    # Aレコードの追加
                    Add-DnsServerResourceRecordA -Name $computerName -ZoneName $zoneName -IPv4Address $CurrentIP.IPAddress -CreatePtr
                }

                # SRVレコードの確認
                $dcSrvRecords = Get-DnsServerResourceRecord -ZoneName $zoneName -RRType SRV -ErrorAction SilentlyContinue
                if (-not $dcSrvRecords) {
                    Write-Host "Warning: SRV records may need to be manually verified after domain promotion"
                }
            }

            Write-Host "DNS Server configuration completed."
        }
        catch {
            Write-Host "Error configuring DNS Server: $_"
            Write-Host "Stack Trace: $($_.ScriptStackTrace)"
        }

        # NTPサーバーの設定
        Write-Host "Configuring NTP Server..."
        try {
            # W32Time設定の構成
            $null = w32tm /config /syncfromflags:domhier /update
            $null = w32tm /config /reliable:yes

            # NTPサーバーの詳細設定
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer"
            if (!(Test-Path $regPath)) {
                New-Item -Path $regPath -Force
            }
            Set-ItemProperty -Path $regPath -Name "Enabled" -Value 1 -Type DWord
            Set-ItemProperty -Path $regPath -Name "InputProvider" -Value 1 -Type DWord

            # W32Time設定の最適化
            $configPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"
            if (!(Test-Path $configPath)) {
                New-Item -Path $configPath -Force
            }
            Set-ItemProperty -Path $configPath -Name "MaxPollInterval" -Value 10 -Type DWord
            Set-ItemProperty -Path $configPath -Name "MinPollInterval" -Value 6 -Type DWord
            Set-ItemProperty -Path $configPath -Name "UpdateInterval" -Value 100 -Type DWord
            Set-ItemProperty -Path $configPath -Name "FrequencyCorrectRate" -Value 4 -Type DWord
            Set-ItemProperty -Path $configPath -Name "HoldPeriod" -Value 5 -Type DWord
            
            # パラメータの設定
            $timeParamPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
            if (!(Test-Path $timeParamPath)) {
                New-Item -Path $timeParamPath -Force
            }
            Set-ItemProperty -Path $timeParamPath -Name "Type" -Value "NT5DS" -Type String
            
            # W32Timeサービスの再起動と同期
            Restart-Service w32time -Force
            w32tm /resync /force
            
            # 設定の確認
            Write-Host "NTP Configuration Status:"
            w32tm /query /configuration
            w32tm /query /status

            Write-Host "NTP Server configuration completed."
        } catch {
            Write-Host "Error configuring NTP Server: $_"
            Write-Host "Stack Trace: $($_.ScriptStackTrace)"
        }

        # ファイアウォールルールの追加（DNS用）
        New-NetFirewallRule -DisplayName "DNS TCP Inbound" `
            -Direction Inbound `
            -Action Allow `
            -Protocol TCP `
            -LocalPort 53 `
            -Group "DNS Server"

        New-NetFirewallRule -DisplayName "DNS UDP Inbound" `
            -Direction Inbound `
            -Action Allow `
            -Protocol UDP `
            -LocalPort 53 `
            -Group "DNS Server"

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

        # ADDSインストール後のDNS確認タスクの作成
        $Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument @'
-NoProfile -WindowStyle Hidden -Command "
    Start-Transcript -Path C:\Windows\Temp\dns-check.log
    # DNSレコードの確認と修正
    $zoneName = '${domain_name}'
    $computerName = $env:COMPUTERNAME
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike '*Loopback*' }).IPAddress
    
    # Aレコードの確認と更新
    $aRecord = Get-DnsServerResourceRecord -ZoneName $zoneName -Name $computerName -RRType A -ErrorAction SilentlyContinue
    if (-not $aRecord) {
        Add-DnsServerResourceRecordA -Name $computerName -ZoneName $zoneName -IPv4Address $ip -CreatePtr
    }
    
    # SRVレコードの確認
    Register-DnsClient
    
    # DNS診断の実行
    dcdiag /test:dns /v
    Stop-Transcript
"
'@
        $Trigger = New-ScheduledTaskTrigger -AtStartup
        $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        Register-ScheduledTask -TaskName "VerifyDNSRecords" -Action $Action -Trigger $Trigger -Principal $Principal -Force

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
