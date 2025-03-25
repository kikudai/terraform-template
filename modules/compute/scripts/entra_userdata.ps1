<powershell>
# エラーハンドリングの有効化
$ErrorActionPreference = "Stop"
Start-Transcript -Path C:\Windows\Temp\userdata.log

try {
    # ネットワークアダプターの設定
    $NetworkAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    
    # タイムゾーンの設定
    Set-TimeZone -Id "Tokyo Standard Time"
    
    # RDPの有効化
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    
    # TLS 1.2の有効化（Entra Connect要件）
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
    
    # ドメイン参加
    $domain = "${domain_name}"
    $password = "${domain_admin_password}" | ConvertTo-SecureString -AsPlainText -Force
    $username = "$${domain_netbios_name}\Administrator"
    $credential = New-Object System.Management.Automation.PSCredential($username, $password)
    
    Add-Computer -DomainName $domain -Credential $credential -Restart -Force
    
    Write-Host "初期設定が完了しました。システムを再起動します。"
} catch {
    Write-Host "エラーが発生しました: $_"
    Write-Host "スタックトレース: $($_.ScriptStackTrace)"
    throw
} finally {
    Stop-Transcript
}
</powershell> 