```

# -------------------------------
# 設定パラメータ（必要に応じて編集）
# -------------------------------
$folderPath = "C:\Shared"
$shareName = "Shared"
$domainName = "${domain_netbios_name}"                      # ドメイン名
$groupName = "SalesGroup"                    # グループ名（CN）
$domainGroup = "${domain_name}\$groupName"      # フル指定（EXAMPLE\SalesGroup）
$ntfsPermission = "Modify"                   # NTFS権限（Read, Modify, FullControlなど）
$sharePermission = "Change"                  # 共有アクセス権（Read, Change, Full）
$ouPath = "OU=Users,DC=example,DC=local"     # グループを作成するOU（必要に応じて変更）

```