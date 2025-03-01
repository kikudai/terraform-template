# PowerShell スクリプトのエラーハンドリングを有効化
$ErrorActionPreference = "Stop"
Start-Transcript -Path C:\Windows\Temp\userdata.log

try {
    if (${install_adds}) {
        Write-Host "Active Directory Domain Services のインストールを開始します..."
        
        # Active Directory のインストール
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
        Install-WindowsFeature -Name DNS -IncludeManagementTools

        # AD ドメインの設定
        $domainName = "${domain_name}"
        $NetBIOSName = "${domain_netbios_name}"

        # 管理者パスワード
        $AdminPassword = ConvertTo-SecureString "${domain_admin_password}" -AsPlainText -Force
        $AdminCred = New-Object System.Management.Automation.PSCredential ("Administrator", $AdminPassword)

        # ドメインコントローラー昇格
        Install-ADDSForest `
            -DomainName $domainName `
            -DomainNetbiosName $NetBIOSName `
            -SafeModeAdministratorPassword $AdminPassword `
            -InstallDns `
            -Force `
            -NoRebootOnCompletion

        Write-Host "Active Directory Domain Services のインストールが完了しました。"
    }

    # RDP を有効化
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

    # Windows ファイアウォールで RDP を許可
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    Write-Host "セットアップが完了しました。システムを再起動します。"
} catch {
    Write-Host "エラーが発生しました: $_"
    throw
} finally {
    Stop-Transcript
}

# システムの再起動
Restart-Computer -Force
