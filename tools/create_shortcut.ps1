$ws = New-Object -ComObject WScript.Shell
$widgetDir = "C:\Users\Admin\Desktop\위젯"
$widgetFile = "$widgetDir\qa-widget.ps1"
$configDir = "$widgetDir\config"

# config\qa_config_*.json 파일 자동 감지 → 각각 바로가기 생성
$configs = Get-ChildItem $configDir -Filter "qa_config_*.json"

foreach ($cfg in $configs) {
    # qa_config_6차.json → "6차 위젯"
    $milestone = $cfg.BaseName -replace "^qa_config_", ""
    $shortcutName = "$milestone 위젯.lnk"
    $shortcutPath = Join-Path $widgetDir $shortcutName

    $sc = $ws.CreateShortcut($shortcutPath)
    $sc.TargetPath = "powershell.exe"
    $sc.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$widgetFile`" -ConfigFile `"$($cfg.Name)`""
    $sc.WorkingDirectory = $widgetDir
    $sc.Save()

    Write-Host "생성: $shortcutName"
}

Write-Host "완료 — 위젯 폴더 안에 바로가기가 생성됐습니다."
