$ws = New-Object -ComObject WScript.Shell

# tools/ 의 부모 = 레포 루트 (팀원이 레포를 어디에 두든 자동 인식)
$repoRoot   = Split-Path $PSScriptRoot -Parent
$widgetFile = Join-Path $repoRoot "qa-widget.ps1"
$configDir  = Join-Path $repoRoot "config"
$desktop    = [Environment]::GetFolderPath("Desktop")

# config\qa_config_*.json 자동 감지 (template 제외) → 차수별 바로가기 생성
$configs = Get-ChildItem $configDir -Filter "qa_config_*.json" |
    Where-Object { $_.BaseName -ne "qa_config_template" }

foreach ($cfg in $configs) {
    # qa_config_6차.json → "6차 위젯"
    $milestone = $cfg.BaseName -replace "^qa_config_", ""
    $shortcutName = "$milestone 위젯.lnk"
    $shortcutPath = Join-Path $desktop $shortcutName

    $sc = $ws.CreateShortcut($shortcutPath)
    $sc.TargetPath = "powershell.exe"
    $sc.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$widgetFile`" -ConfigFile `"$($cfg.Name)`""
    $sc.WorkingDirectory = $repoRoot
    $sc.Save()

    Write-Host "생성: $shortcutName ($($cfg.Name))"
}

Write-Host "완료 — 바탕화면에 차수별 위젯 바로가기가 생성됐습니다."
