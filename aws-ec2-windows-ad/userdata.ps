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

Restart-Computer
