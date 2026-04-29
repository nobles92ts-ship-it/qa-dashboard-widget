$path = 'C:\Users\Admin\Desktop\위젯\qa-widget.ps1'
$content = Get-Content $path -Raw -Encoding UTF8
$utf8bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($path, $content, $utf8bom)
Write-Host "UTF-8 BOM 인코딩 완료"
