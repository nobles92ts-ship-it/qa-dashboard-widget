param(
    [string]$ConfigFile = "qa_config_6차.json"
)

$scriptRoot = $PSScriptRoot
$scriptsDir = Join-Path $scriptRoot "scripts"
$credDir    = Join-Path $scriptRoot "credentials"
$configPath = Join-Path $scriptRoot "config\$ConfigFile"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  QA Dashboard 팀원 셋업 스크립트" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$ok = $true

# 1. Node.js 확인
Write-Host "[1/5] Node.js 확인..." -NoNewline
if (Get-Command node -ErrorAction SilentlyContinue) {
    $ver = node --version
    Write-Host " OK ($ver)" -ForegroundColor Green
} else {
    Write-Host " 없음" -ForegroundColor Red
    Write-Host "      → https://nodejs.org 에서 설치 후 다시 실행하세요." -ForegroundColor Yellow
    $ok = $false
}

# 2. Vercel CLI 확인
Write-Host "[2/5] Vercel CLI 확인..." -NoNewline
if (Get-Command vercel -ErrorAction SilentlyContinue) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " 없음" -ForegroundColor Red
    Write-Host "      → 설치: npm install -g vercel" -ForegroundColor Yellow
    Write-Host "      → 설치 후: vercel login" -ForegroundColor Yellow
    $ok = $false
}

# 3. Google credentials 확인
Write-Host "[3/5] Google 인증 파일 확인..." -NoNewline
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
Write-Host "[4/5] Slack 설정 확인..." -NoNewline
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

# 6. config 로컬 경로 확인
Write-Host ""
Write-Host "[추가] config 로컬 경로 확인..." -ForegroundColor Cyan
if (Test-Path $configPath) {
    $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
    $needsUpdate = $false
    if ($cfg.deployDir -like "*YOUR_NAME*") {
        Write-Host "      → config/$ConfigFile 의 deployDir 를 본인 경로로 수정하세요." -ForegroundColor Yellow
        $needsUpdate = $true
    }
    if ($cfg.htmlTemplate -like "*YOUR_NAME*") {
        Write-Host "      → config/$ConfigFile 의 htmlTemplate 를 본인 경로로 수정하세요." -ForegroundColor Yellow
        $needsUpdate = $true
    }
    if (-not $needsUpdate) {
        Write-Host "      경로 설정 OK" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
if ($ok) {
    Write-Host "  모든 설정 완료! 위젯을 실행해도 됩니다." -ForegroundColor Green
    Write-Host "  실행: powershell -ExecutionPolicy Bypass -File qa-widget.ps1 -ConfigFile $ConfigFile" -ForegroundColor White
} else {
    Write-Host "  위 항목을 해결한 뒤 다시 setup.ps1 을 실행하세요." -ForegroundColor Yellow
}
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
