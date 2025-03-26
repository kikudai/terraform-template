# ドメイン参加用のパラメータ
param(
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    
    [Parameter(Mandatory=$true)]
    [string]$DomainNetbiosName,
    
    [Parameter(Mandatory=$true)]
    [string]$AdServerIP
)

try {
    # DNSサーバーの設定
    Write-Host "Configuring DNS settings..."
    $adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    $interfaceIndex = $adapter.ifIndex
    
    # ADサーバーのIPをDNSサーバーとして設定
    Write-Host "Setting AD server as DNS server..."
    Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses $AdServerIP
    
    # DNS設定の確認
    $dnsSettings = Get-DnsClientServerAddress -InterfaceIndex $interfaceIndex
    Write-Host "Current DNS settings:"
    Write-Host $dnsSettings | Format-Table
    
    # DNSキャッシュのクリア
    Write-Host "Flushing DNS cache..."
    Clear-DnsClientCache

    # ADサーバーの可用性チェック
    Write-Host "Checking AD server availability..."
    if (-not (Test-Connection -ComputerName $AdServerIP -Count 1 -Quiet)) {
        throw "Cannot reach AD server at $AdServerIP"
    }

    # 管理者資格情報の入力を要求
    $username = "$DomainNetbiosName\Administrator"
    $securePassword = Read-Host "Enter domain admin password" -AsSecureString
    $credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

    # ドメイン参加を試行
    Write-Host "Attempting to join domain: $DomainName"
    Add-Computer -DomainName $DomainName -Credential $credential -Restart -Force -Verbose

    Write-Host "Successfully joined domain. System will restart."
} catch {
    Write-Host "Error: $_"
    Write-Host "Stack Trace: $($_.ScriptStackTrace)"
    exit 1
}