<powershell>
# 実行ポリシーを設定
Set-ExecutionPolicy Bypass -Scope Process -Force

# スクリプトの先頭に追加
$VerbosePreference = "Continue"
Start-Transcript -Path "C:\Windows\Temp\userdata_debug.log" -Force

# 基本的なログ出力の設定
$baseLogPath = "C:\Windows\Temp"
$startLogPath = "$baseLogPath\entra_userdata_start.log"
$mainLogPath = "$baseLogPath\userdata.log"
$errorLogPath = "$baseLogPath\entra_userdata_error.log"
$completeLogPath = "$baseLogPath\entra_userdata_complete.log"

# 初期ログ出力（スクリプトが開始されたことを確認）
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
New-Item -Path $startLogPath -ItemType File -Force
Add-Content -Path $startLogPath -Value "[$timestamp] Starting Entra Connect Server setup"

# エラーハンドリングの有効化
$ErrorActionPreference = "Stop"

# トランスクリプトの開始
try {
    Stop-Transcript -ErrorAction SilentlyContinue
} catch {}

try {
    Start-Transcript -Path $mainLogPath -Force
    Write-Host "Starting Entra Connect Server configuration at $timestamp"

    # ネットワークアダプターの設定
    $NetworkAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    
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
    
    # RDPの有効化
    Write-Host "Configuring RDP access..."
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1
    
    # RDPのファイアウォールルールを直接作成
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
    
    # TLS 1.2の有効化（Entra Connect要件）
    Write-Host "Configuring TLS 1.2 settings..."
    $tls12RegPath = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client",
        "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
    )
    
    foreach ($path in $tls12RegPath) {
        New-Item -Path $path -Force
        New-ItemProperty -Path $path -Name "Enabled" -Value 1 -PropertyType "DWord" -Force
        New-ItemProperty -Path $path -Name "DisabledByDefault" -Value 0 -PropertyType "DWord" -Force
    }
    
    # .NET Frameworkの設定
    $netFrameworkPaths = @(
        "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"
    )
    
    foreach ($path in $netFrameworkPaths) {
        New-ItemProperty -Path $path -Name "SchUseStrongCrypto" -Value 1 -PropertyType "DWord" -Force
    }

    # 不要なサービスの無効化
    Write-Host "Disabling unnecessary services..."
    sc.exe config MapsBroker start= disabled
    sc.exe config AWSLiteAgent start= disabled

    # DNSサーバーの設定
    Write-Host "Configuring DNS settings..."
    try {
        $adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
        $interfaceIndex = $adapter.ifIndex
        
        # ADサーバーのIPをDNSサーバーとして設定
        Write-Host "Setting AD server as DNS server..."
        Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses "${windows_ad_private_ip}"
        
        # DNS設定の確認
        $dnsSettings = Get-DnsClientServerAddress -InterfaceIndex $interfaceIndex
        Write-Host "Current DNS settings:"
        Write-Host $dnsSettings | Format-Table
        
        # DNSキャッシュのクリア
        Write-Host "Flushing DNS cache..."
        Clear-DnsClientCache
    } catch {
        Write-Host "Error configuring DNS settings: $_"
        Write-Host "Stack Trace: $($_.ScriptStackTrace)"
        throw
    }

    # ADサーバーが利用可能になるまで待機
    $domain = "${domain_name}"
    $maxAttempts = 30
    ${attempt} = 0
    $success = $false

    Write-Host "Waiting for AD server to become available..."
    do {
        ${attempt}++
        try {
            $result = Test-NetConnection -ComputerName "${windows_ad_private_ip}" -Port 389 -WarningAction SilentlyContinue
            if ($result.TcpTestSucceeded) {
                Write-Host "AD server is available!"
                $success = $true
                break
            }
        } catch {
            Write-Host "Attempt ${attempt}: AD server not yet available..."
        }
        Start-Sleep -Seconds 30
    } while (${attempt} -lt $maxAttempts)

    if (-not $success) {
        throw "AD server did not become available within the timeout period"
    }

    # 追加の待機時間（ADサービスの完全な起動を待つ）
    Write-Host "Waiting additional time for AD services to be fully operational..."
    Start-Sleep -Seconds 180
    
    # AWS Systems Managerからパスワードを取得
    Write-Host "Getting AD admin password from AWS Systems Manager..."
    try {
        # AWS Tools for PowerShellモジュールのインストール（必要な場合）
        if (!(Get-Module -ListAvailable -Name AWS.Tools.SimpleSystemsManagement)) {
            Install-Module -Name AWS.Tools.SimpleSystemsManagement -Force
        }

        # リージョンの設定
        $region = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Uri http://169.254.169.254/latest/meta-data/placement/region
        Set-DefaultAWSRegion -Region $region

        # パラメータストアからパスワードを取得
        $parameterName = "/ad/admin/password"  # パラメータ名は適宜変更してください
        $securePassword = (Get-SSMParameter -Name $parameterName -WithDecryption $true).Value
    } catch {
        Write-Host "Error getting password from SSM: $_"
        Write-Host "Stack Trace: $($_.ScriptStackTrace)"
        throw
    }

    # ドメイン参加用のクレデンシャルを作成
    $password = $securePassword | ConvertTo-SecureString -AsPlainText -Force
    $username = "$${domain_netbios_name}\Administrator"
    $credential = New-Object System.Management.Automation.PSCredential($username, $password)

    # ドメイン参加を試行
    Write-Host "Attempting to join domain: $domain"
    try {
        Add-Computer -DomainName $domain -Credential $credential -Restart -Force -Verbose
        Write-Host "Successfully joined domain. System will restart."
    } catch {
        Write-Host "Error joining domain: $_"
        Write-Host "Stack Trace: $($_.ScriptStackTrace)"
        throw
    }

    Write-Host "初期設定が完了しました。システムを再起動します。"
} catch {
    $errorMessage = "エラーが発生しました: $_`nスタックトレース: $($_.ScriptStackTrace)"
    Write-Host $errorMessage
    $errorMessage | Out-File -FilePath $errorLogPath -Force
    throw
} finally {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    Add-Content -Path $completeLogPath -Value "[$timestamp] Completing Entra Connect Server setup"
    Stop-Transcript
}

# Restart system
Restart-Computer -Force
</powershell> 