param(
    [string]$ConfigFile = ""
)

$scriptRoot = $PSScriptRoot
$scriptsDir = Join-Path $scriptRoot "scripts"
$credDir    = Join-Path $scriptRoot "credentials"
$configDir  = Join-Path $scriptRoot "config"

# ── 차수 선택 (파라미터 미지정 시 대화형) ──
if (-not $ConfigFile) {
    $configs = @(Get-ChildItem $configDir -Filter "qa_config_*.json" |
        Where-Object { $_.BaseName -ne "qa_config_template" } | Sort-Object Name)
    if ($configs.Count -eq 0) {
        Write-Host "config/ 폴더에 qa_config_*.json 이 없습니다." -ForegroundColor Red
        return
    }
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  어떤 차수의 위젯을 설정할까요?" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    for ($i = 0; $i -lt $configs.Count; $i++) {
        $m = $configs[$i].BaseName -replace "^qa_config_", ""
        Write-Host ("   [{0}] {1}" -f ($i + 1), $m)
    }
    Write-Host ""
    $sel = Read-Host "번호 선택 (1-$($configs.Count))"
    $idx = 0
    if (-not [int]::TryParse($sel, [ref]$idx) -or $idx -lt 1 -or $idx -gt $configs.Count) {
        Write-Host "잘못된 입력입니다. setup.ps1 을 다시 실행하세요." -ForegroundColor Red
        return
    }
    $ConfigFile = $configs[$idx - 1].Name
}

$configPath = Join-Path $configDir $ConfigFile
$milestone  = ($ConfigFile -replace "^qa_config_", "") -replace "\.json$", ""

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  QA Dashboard 셋업 — $milestone 위젯" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$ok = $true

# 1. Node.js 확인
Write-Host "[1/6] Node.js 확인..." -NoNewline
if (Get-Command node -ErrorAction SilentlyContinue) {
    $ver = node --version
    Write-Host " OK ($ver)" -ForegroundColor Green
} else {
    Write-Host " 없음" -ForegroundColor Red
    Write-Host "      → https://nodejs.org 에서 설치 후 다시 실행하세요." -ForegroundColor Yellow
    $ok = $false
}

# 2. Vercel CLI 확인
Write-Host "[2/6] Vercel CLI 확인..." -NoNewline
if (Get-Command vercel -ErrorAction SilentlyContinue) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " 없음" -ForegroundColor Red
    Write-Host "      → 설치: npm install -g vercel" -ForegroundColor Yellow
    Write-Host "      → 설치 후: vercel login" -ForegroundColor Yellow
    $ok = $false
}

# 3. Google credentials 확인
Write-Host "[3/6] Google 인증 파일 확인..." -NoNewline
$clientSecret = Join-Path $credDir "client_secret.json"
$oauthToken   = Join-Path $credDir "oauth_token.json"
if (Test-Path $clientSecret) {
    Write-Host " client_secret.json OK" -ForegroundColor Green
    if (-not (Test-Path $oauthToken)) {
        Write-Host "      → oauth_token.json 없음. 최초 인증이 필요합니다." -ForegroundColor Yellow
        Write-Host "      → 실행: node scripts/google_auth.js" -ForegroundColor Yellow
        $ok = $false
    } else {
        Write-Host "         oauth_token.json OK" -ForegroundColor Green
    }
} else {
    Write-Host " 없음" -ForegroundColor Red
    Write-Host "      → 팀장에게 credentials/client_secret.json 파일을 받아 넣어주세요." -ForegroundColor Yellow
    $ok = $false
}

# 4. Slack 토큰 확인
Write-Host "[4/6] Slack 설정 확인..." -NoNewline
$slackConfig = Join-Path $scriptsDir "slack_config.json"
if (Test-Path $slackConfig) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " 없음" -ForegroundColor Red
    Write-Host "      → scripts/slack_config.json 파일을 생성하세요:" -ForegroundColor Yellow
    Write-Host '         { "token": "xoxb-팀장에게_받은_토큰" }' -ForegroundColor Gray
    $ok = $false
}

# 5. Vercel 토큰 확인
Write-Host "[5/6] Vercel 토큰 확인..." -NoNewline
$vercelConfig = Join-Path $scriptsDir "vercel_config.json"
if (Test-Path $vercelConfig) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " 없음" -ForegroundColor Red
    Write-Host "      → scripts/vercel_config.json 파일을 생성하세요:" -ForegroundColor Yellow
    Write-Host '         { "token": "팀장에게_받은_Vercel_토큰" }' -ForegroundColor Gray
    Write-Host "      → Vercel 토큰은 팀장에게 메신저로 요청하세요." -ForegroundColor Gray
    $ok = $false
}

# 6. Jira 설정 확인
Write-Host "[6/6] Jira 설정 확인..." -NoNewline
$jiraConfig = Join-Path $scriptsDir "jira_config.json"
if (Test-Path $jiraConfig) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " 없음" -ForegroundColor Red
    Write-Host "      → scripts/jira_config.json 파일을 생성하세요:" -ForegroundColor Yellow
    Write-Host '         { "email": "본인_Atlassian_이메일", "token": "본인_API_토큰" }' -ForegroundColor Gray
    Write-Host "      → Jira API 토큰 발급: https://id.atlassian.com/manage-profile/security/api-tokens" -ForegroundColor Gray
    $ok = $false
}

# config 로컬 경로 확인 (배포 버튼용 — 없어도 조회는 가능)
Write-Host ""
Write-Host "[추가] $milestone config 로컬 경로 확인..." -ForegroundColor Cyan
if (Test-Path $configPath) {
    $cfg = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $needsUpdate = $false
    if ($cfg.deployDir -like "*YOUR_NAME*") {
        Write-Host "      → config/$ConfigFile 의 deployDir 를 본인 경로로 수정하세요. (리포트 배포 시 필요)" -ForegroundColor Yellow
        $needsUpdate = $true
    }
    if ($cfg.htmlTemplate -like "*YOUR_NAME*") {
        Write-Host "      → config/$ConfigFile 의 htmlTemplate 를 본인 경로로 수정하세요. (리포트 배포 시 필요)" -ForegroundColor Yellow
        $needsUpdate = $true
    }
    if (-not $needsUpdate) {
        Write-Host "      경로 설정 OK" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
if ($ok) {
    Write-Host "  $milestone 설정 완료!" -ForegroundColor Green

    # 바탕화면에 선택한 차수 바로가기 생성
    $widgetFile = Join-Path $scriptRoot "qa-widget.ps1"
    $desktop    = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktop "$milestone 위젯.lnk"
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($shortcutPath)
    $sc.TargetPath = "powershell.exe"
    $sc.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$widgetFile`" -ConfigFile `"$ConfigFile`""
    $sc.WorkingDirectory = $scriptRoot
    $sc.Save()
    Write-Host "  바탕화면에 '$milestone 위젯' 바로가기를 만들었습니다." -ForegroundColor Green
    Write-Host ""

    $run = Read-Host "지금 $milestone 위젯을 실행할까요? (Y/n)"
    if ($run -ne "n" -and $run -ne "N") {
        Start-Process "powershell" "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$widgetFile`" -ConfigFile `"$ConfigFile`""
        Write-Host "  $milestone 위젯을 실행했습니다." -ForegroundColor Green
    } else {
        Write-Host "  나중에 바탕화면의 '$milestone 위젯' 을 더블클릭하면 실행됩니다." -ForegroundColor White
    }
} else {
    Write-Host "  위 항목을 해결한 뒤 다시 실행하세요 (선택한 차수: $milestone)." -ForegroundColor Yellow
    Write-Host "  다시 실행: powershell -ExecutionPolicy Bypass -File setup.ps1" -ForegroundColor White
}
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
