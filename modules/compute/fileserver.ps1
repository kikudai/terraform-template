# -------------------------------
# ファイルサーバー構築
# -------------------------------

# 設定パラメータ（必要に応じて編集）
$folderPath = "C:\Shared"
$shareName = "Shared"
$netbiosName = "${domain_netbios_name}"
$topDomainName = "${top_domain_name}"
$secondDomainName = "${second_domain_name}"
$ouName = "ユーザー"
$ouPath = "OU=$ouName,DC=$secondDomainName,DC=$topDomainName"
$ouParentPath = "DC=$secondDomainName,DC=$topDomainName"  # OU作成用に親を指定
$groupName = "SalesGroup"                     # グループ名
$domainGroup = "$netbiosName\$groupName"      # ドメイン\グループ名
$ntfsPermission = "Modify"                    # NTFSアクセス権
$sharePermission = "Change"                   # 共有アクセス権: Read / Change / Full

# モジュール読み込み（AD操作用）
Import-Module ActiveDirectory

# フォルダ作成
if (!(Test-Path -Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory
    Write-Host "📁 フォルダ作成: $folderPath"
} else {
    Write-Host "📁 フォルダは既に存在します: $folderPath"
}

    # OU の存在チェックと作成
    try {
        Get-ADOrganizationalUnit -Identity $ouPath -ErrorAction Stop | Out-Null
        Write-Host "✅ OU は存在します: $ouPath"
    } catch {
        Write-Host "📂 OU が存在しません。作成します: $ouPath"
        New-ADOrganizationalUnit -Path $ouParentPath -Name $ouName
        Write-Host "✅ OU を作成しました: $ouPath"
    }

# グループの存在チェックと作成
try {
    Get-ADGroup -Identity $groupName -ErrorAction Stop | Out-Null
    Write-Host "✅ グループは存在します: $domainGroup"
} catch {
    Write-Host "👥 グループが存在しません。作成します: $domainGroup"
    New-ADGroup -Name $groupName -SamAccountName $groupName -GroupScope Global -GroupCategory Security -Path $ouPath
    Write-Host "✅ グループを作成しました: $domainGroup"
}

# NTFSアクセス権の設定
$acl = Get-Acl $folderPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($domainGroup, $ntfsPermission, "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl $folderPath $acl
Write-Host "🔐 NTFSアクセス許可を設定: $domainGroup → $ntfsPermission"

# ファイル共有アクセス権リセット（SMBプロトコル）
if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
    Remove-SmbShare -Name $shareName -Force
    Write-Host "🧹 既存の共有 '$shareName' を削除しました"
}

# ファイル共有作成（SMBプロトコル、共有アクセス権に応じて分岐）
switch ($sharePermission) {
    "Read" {
        New-SmbShare -Name $shareName -Path $folderPath -ReadAccess $domainGroup
        Write-Host "📡 共有 '$shareName' を作成（ReadAccess）: \\$env:COMPUTERNAME\$shareName"
    }
    "Change" {
        New-SmbShare -Name $shareName -Path $folderPath -ChangeAccess $domainGroup
        Write-Host "📡 共有 '$shareName' を作成（ChangeAccess）: \\$env:COMPUTERNAME\$shareName"
    }
    "Full" {
        New-SmbShare -Name $shareName -Path $folderPath -FullAccess $domainGroup
        Write-Host "📡 共有 '$shareName' を作成（FullAccess）: \\$env:COMPUTERNAME\$shareName"
    }
    default {
        Write-Error "❌ 無効な共有アクセス権: $sharePermission。Read / Change / Full のいずれかを指定してください。"
        return
    }
}
# ファイルサーバー構築終了
# -------------------------------
