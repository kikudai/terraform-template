# Active Directory のインストール
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature -Name DNS -IncludeManagementTools

# AD ドメインの設定
$domainName = "example.local"
$NetBIOSName = "EXAMPLE"

# 管理者パスワード
$AdminPassword = ConvertTo-SecureString "YourSecurePassword!" -AsPlainText -Force
$AdminCred = New-Object System.Management.Automation.PSCredential ("Administrator", $AdminPassword)

# ドメインコントローラー昇格
Install-ADDSForest -DomainName $domainName -DomainNetbiosName $NetBIOSName -SafeModeAdministratorPassword $AdminPassword -InstallDns -Confirm:$false -Force

# 🔹 RDP を有効化
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

# 🔹 Windows ファイアウォールで RDP を許可
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# 🔹 ネットワークレベル認証 (NLA) を無効化 (必要に応じて)
# Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0

Restart-Computer
