param(
    [string]$ConfigFile = "qa_config_6차.json"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── 설정 ──
$scriptDir = if ($cfg.scriptDir) { $cfg.scriptDir } else { Join-Path $PSScriptRoot "scripts" }
$refreshMin = 5

# ── Config 로드 ──
$configPath = Join-Path $PSScriptRoot "config\$ConfigFile"
$configFullPath = $configPath  # node 스크립트에 전체 경로 전달용
if (Test-Path $configPath) {
    $cfg = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
    # 폴백: 기본값
    $cfg = [PSCustomObject]@{
        milestone  = "6차"
        tcSheetUrl = "https://docs.google.com/spreadsheets/d/1Wg9569P2nNkDauWkw0kMnxzDTmEO5OBcpilr2KA-NXs/edit"
        reportUrl  = "https://qa-report-deploy-phi.vercel.app/6차/"
        statusFile = "qa_status_6차.json"
    }
}

$statusFile = Join-Path $scriptDir $cfg.statusFile

# ── 폼 생성 (다크 테마, 항상 위) ──
$form = New-Object System.Windows.Forms.Form
$form.Text = "QA Dashboard"
$form.StartPosition = "Manual"
$form.TopMost = $true
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F1923")
$form.ForeColor = [System.Drawing.Color]::White
$form.ShowInTaskbar = $true
$form.Opacity = 0.95
$form.ClientSize = New-Object System.Drawing.Size(208, 348)
$sw = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width
$form.Location = New-Object System.Drawing.Point(($sw - 240), 60)

# ── 폰트 ──
$fontTitle  = New-Object System.Drawing.Font("Malgun Gothic", 11, [System.Drawing.FontStyle]::Bold)
$fontSmall  = New-Object System.Drawing.Font("Malgun Gothic", 8)
$fontSmallB = New-Object System.Drawing.Font("Malgun Gothic", 8, [System.Drawing.FontStyle]::Bold)
$fontKPI    = New-Object System.Drawing.Font("Malgun Gothic", 13, [System.Drawing.FontStyle]::Bold)
$fontDot    = New-Object System.Drawing.Font("Malgun Gothic", 9)
$fontTiny   = New-Object System.Drawing.Font("Malgun Gothic", 7)

# ── 타이틀 ──
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "$($cfg.milestone) QA Dashboard"
$lblTitle.Font = $fontTitle
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.Location = New-Object System.Drawing.Point(12, 8)
$lblTitle.Size = New-Object System.Drawing.Size(145, 22)
$form.Controls.Add($lblTitle)

# ── 새로고침 버튼 (타이틀 우측 소형) ──
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "↺"
$btnRefresh.Font = $fontSmall
$btnRefresh.FlatStyle = "Flat"
$btnRefresh.FlatAppearance.BorderSize = 1
$btnRefresh.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#374151")
$btnRefresh.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1F2937")
$btnRefresh.FlatAppearance.MouseOverBackColor = [System.Drawing.ColorTranslator]::FromHtml("#374151")
$btnRefresh.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#9CA3AF")
$btnRefresh.Cursor = "Hand"
$btnRefresh.TextAlign = "MiddleCenter"
$btnRefresh.Location = New-Object System.Drawing.Point(170, 8)
$btnRefresh.Size = New-Object System.Drawing.Size(28, 22)
$form.Controls.Add($btnRefresh)

# ── 날짜 / 상태 ──
$lblDate = New-Object System.Windows.Forms.Label
$lblDate.Text = (Get-Date -Format "yyyy.MM.dd (ddd)")
$lblDate.Font = $fontTiny
$lblDate.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#6B7280")
$lblDate.Location = New-Object System.Drawing.Point(12, 33)
$lblDate.Size = New-Object System.Drawing.Size(90, 14)
$form.Controls.Add($lblDate)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = ""
$lblStatus.Font = $fontTiny
$lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#4B5563")
$lblStatus.Location = New-Object System.Drawing.Point(104, 33)
$lblStatus.Size = New-Object System.Drawing.Size(92, 14)
$lblStatus.TextAlign = "MiddleRight"
$form.Controls.Add($lblStatus)

# ── 구분선 헬퍼 ──
function New-Divider($y) {
    $line = New-Object System.Windows.Forms.Label
    $line.Location = New-Object System.Drawing.Point(12, $y)
    $line.Size = New-Object System.Drawing.Size(184, 1)
    $line.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1F2937")
    return $line
}

$line1 = New-Divider 51
$form.Controls.Add($line1)

# ── KPI 행 팩토리 ──
function New-KPIRow($y, $label, $color) {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(12, $y)
    $panel.Size = New-Object System.Drawing.Size(184, 26)
    $panel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#111827")

    $accent = New-Object System.Windows.Forms.Label
    $accent.Location = New-Object System.Drawing.Point(0, 0)
    $accent.Size = New-Object System.Drawing.Size(3, 26)
    $accent.BackColor = [System.Drawing.ColorTranslator]::FromHtml($color)
    $panel.Controls.Add($accent)

    $dot = New-Object System.Windows.Forms.Label
    $dot.Text = "●"
    $dot.Font = $fontDot
    $dot.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($color)
    $dot.Location = New-Object System.Drawing.Point(8, 0)
    $dot.Size = New-Object System.Drawing.Size(14, 26)
    $dot.TextAlign = "MiddleCenter"
    $panel.Controls.Add($dot)

    $name = New-Object System.Windows.Forms.Label
    $name.Text = $label
    $name.Font = $fontSmall
    $name.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#D1D5DB")
    $name.Location = New-Object System.Drawing.Point(26, 0)
    $name.Size = New-Object System.Drawing.Size(66, 26)
    $name.TextAlign = "MiddleLeft"
    $panel.Controls.Add($name)

    $num = New-Object System.Windows.Forms.Label
    $num.Name = "num"
    $num.Text = "-"
    $num.Font = $fontKPI
    $num.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($color)
    $num.Location = New-Object System.Drawing.Point(96, 0)
    $num.Size = New-Object System.Drawing.Size(84, 26)
    $num.TextAlign = "MiddleRight"
    $panel.Controls.Add($num)

    return $panel
}

function New-Sep($y) {
    $sep = New-Object System.Windows.Forms.Label
    $sep.Location = New-Object System.Drawing.Point(12, $y)
    $sep.Size = New-Object System.Drawing.Size(184, 1)
    $sep.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E2D3D")
    return $sep
}

$kpi1 = New-KPIRow 55  "PASS"   "#10B981"
$kpi2 = New-KPIRow 82  "FAIL"   "#EF4444"
$kpi3 = New-KPIRow 109 "BLOCK"  "#F59E0B"
$kpi4 = New-KPIRow 136 "미진행" "#6B7280"
$kpi5 = New-KPIRow 163 "N/A"    "#9CA3AF"

$sep1 = New-Sep 81
$sep2 = New-Sep 108
$sep3 = New-Sep 135
$sep4 = New-Sep 162

$form.Controls.Add($kpi1)
$form.Controls.Add($sep1)
$form.Controls.Add($kpi2)
$form.Controls.Add($sep2)
$form.Controls.Add($kpi3)
$form.Controls.Add($sep3)
$form.Controls.Add($kpi4)
$form.Controls.Add($sep4)
$form.Controls.Add($kpi5)

$line2 = New-Divider 192
$form.Controls.Add($line2)

# ── 진행률 ──
$lblProgress = New-Object System.Windows.Forms.Label
$lblProgress.Text = "PC 진행률  --%"
$lblProgress.Font = $fontSmall
$lblProgress.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#9CA3AF")
$lblProgress.Location = New-Object System.Drawing.Point(12, 196)
$lblProgress.Size = New-Object System.Drawing.Size(184, 14)
$form.Controls.Add($lblProgress)

$progressBg = New-Object System.Windows.Forms.Panel
$progressBg.Location = New-Object System.Drawing.Point(12, 213)
$progressBg.Size = New-Object System.Drawing.Size(184, 7)
$progressBg.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1F2937")
$form.Controls.Add($progressBg)

$progressFill = New-Object System.Windows.Forms.Panel
$progressFill.Location = New-Object System.Drawing.Point(0, 0)
$progressFill.Size = New-Object System.Drawing.Size(0, 7)
$progressFill.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3B82F6")
$progressBg.Controls.Add($progressFill)

$lblDetail = New-Object System.Windows.Forms.Label
$lblDetail.Text = "Loading..."
$lblDetail.Font = $fontTiny
$lblDetail.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#6B7280")
$lblDetail.Location = New-Object System.Drawing.Point(12, 223)
$lblDetail.Size = New-Object System.Drawing.Size(184, 14)
$form.Controls.Add($lblDetail)

# ── N/A 제외 안내 ──
$lblNAText = New-Object System.Windows.Forms.Label
$lblNAText.Text = ""
$lblNAText.Font = $fontTiny
$lblNAText.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#6B7280")
$lblNAText.Location = New-Object System.Drawing.Point(12, 237)
$lblNAText.Size = New-Object System.Drawing.Size(184, 14)
$form.Controls.Add($lblNAText)

$line3 = New-Divider 254
$form.Controls.Add($line3)

# ── 둥근 모서리 헬퍼 ──
function Set-Rounded($ctrl, $r = 5) {
    $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $gp.AddArc(0, 0, $d, $d, 180, 90)
    $gp.AddArc($ctrl.Width - $d, 0, $d, $d, 270, 90)
    $gp.AddArc($ctrl.Width - $d, $ctrl.Height - $d, $d, $d, 0, 90)
    $gp.AddArc(0, $ctrl.Height - $d, $d, $d, 90, 90)
    $gp.CloseAllFigures()
    $ctrl.Region = New-Object System.Drawing.Region($gp)
}

# ── 버튼 팩토리 ──
function New-FlatButton($x, $y, $w, $h, $text, $font, $bg, $hover) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Size = New-Object System.Drawing.Size($w, $h)
    $btn.Text = $text
    $btn.Font = $font
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml($bg)
    $btn.FlatAppearance.MouseOverBackColor = [System.Drawing.ColorTranslator]::FromHtml($hover)
    $btn.FlatAppearance.MouseDownBackColor = [System.Drawing.ColorTranslator]::FromHtml($bg)
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Cursor = "Hand"
    $btn.TextAlign = "MiddleCenter"
    return $btn
}

# ── QA 의견 입력 다이얼로그 ──
function Show-OpinionDialog {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "QA 의견 입력"
    $dlg.Size = New-Object System.Drawing.Size(400, 265)
    $dlg.StartPosition = "CenterScreen"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0F1923")
    $dlg.ForeColor = [System.Drawing.Color]::White
    $dlg.TopMost = $true

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "이번 테스트 결과에 대한 QA 의견을 입력하세요:"
    $lbl.Font = $fontSmall
    $lbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#9CA3AF")
    $lbl.Location = New-Object System.Drawing.Point(12, 10)
    $lbl.Size = New-Object System.Drawing.Size(370, 18)
    $dlg.Controls.Add($lbl)

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Multiline = $true
    $txt.ScrollBars = "Vertical"
    $txt.AcceptsReturn = $true
    $txt.Location = New-Object System.Drawing.Point(12, 34)
    $txt.Size = New-Object System.Drawing.Size(370, 135)
    $txt.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#111827")
    $txt.ForeColor = [System.Drawing.Color]::White
    $txt.Font = $fontSmall
    $txt.BorderStyle = "FixedSingle"
    $opinionFile = Join-Path $scriptDir "qa_opinion.txt"
    if (Test-Path $opinionFile) { $txt.Text = Get-Content $opinionFile -Raw -Encoding UTF8 }
    $dlg.Controls.Add($txt)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "적용 후 최신화"
    $btnOk.Location = New-Object System.Drawing.Point(183, 183)
    $btnOk.Size = New-Object System.Drawing.Size(112, 30)
    $btnOk.FlatStyle = "Flat"
    $btnOk.FlatAppearance.BorderSize = 0
    $btnOk.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1D4ED8")
    $btnOk.ForeColor = [System.Drawing.Color]::White
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dlg.Controls.Add($btnOk)
    $dlg.AcceptButton = $btnOk

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "취소"
    $btnCancel.Location = New-Object System.Drawing.Point(305, 183)
    $btnCancel.Size = New-Object System.Drawing.Size(77, 30)
    $btnCancel.FlatStyle = "Flat"
    $btnCancel.FlatAppearance.BorderSize = 0
    $btnCancel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#374151")
    $btnCancel.ForeColor = [System.Drawing.Color]::White
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dlg.Controls.Add($btnCancel)
    $dlg.CancelButton = $btnCancel

    $result = $dlg.ShowDialog($form)
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) { return $txt.Text }
    return $null
}

# ── 하단 버튼 (3행) ──
$halfW = 90
$btnOpen   = New-FlatButton 12  258 $halfW    26 "리포트"        $fontSmall  "#1E3A5F" "#28527A"
$btnSheet  = New-FlatButton 106 258 $halfW    26 "TC 시트"       $fontSmall  "#1E3A5F" "#28527A"
$btnDeploy = New-FlatButton 12  287 184       26 "리포트 최신화" $fontSmallB "#1D4ED8" "#2563EB"
$btnSlack  = New-FlatButton 12  316 184       26 "Slack 전송"    $fontSmall  "#065F46" "#047857"

Set-Rounded $btnOpen
Set-Rounded $btnSheet
Set-Rounded $btnDeploy
Set-Rounded $btnSlack

$btnOpen.Add_Click({ Start-Process $cfg.reportUrl })
$btnSheet.Add_Click({ Start-Process $cfg.tcSheetUrl })

$btnDeploy.Add_Click({
    $opinion = Show-OpinionDialog
    if ($null -eq $opinion) { return }

    $opinionFile = Join-Path $scriptDir "qa_opinion.txt"
    [System.IO.File]::WriteAllText($opinionFile, $opinion, [System.Text.Encoding]::UTF8)

    $btnDeploy.Text = "최신화 중..."
    $btnDeploy.Enabled = $false
    $form.Refresh()
    $deployDir = $cfg.deployDir
    $scope = $cfg.vercelScope
    $vercelConfigFile = Join-Path $scriptDir "vercel_config.json"
    $vercelToken = ""
    if (Test-Path $vercelConfigFile) {
        $vercelToken = (Get-Content $vercelConfigFile -Raw | ConvertFrom-Json).token
    }
    $tokenFlag = if ($vercelToken) { "--token $vercelToken" } else { "" }
    Start-Process "cmd" "/c cd /d $scriptDir && node update_report.js --config `"$configFullPath`" && cd /d $deployDir && vercel deploy --prod --yes --scope $scope $tokenFlag && echo. && echo [완료] 배포 성공! && timeout /t 3" -WindowStyle Normal
    $btnDeploy.Text = "리포트 최신화"
    $btnDeploy.Enabled = $true
})

$btnSlack.Add_Click({
    $btnSlack.Text = "전송 중..."
    $btnSlack.Enabled = $false
    $form.Refresh()
    Start-Process "cmd" "/c cd /d $scriptDir && node send_slack_qa.js --config `"$configFullPath`" && echo. && echo Slack 전송 완료! && timeout /t 3" -WindowStyle Normal
    $btnSlack.Text = "Slack 전송"
    $btnSlack.Enabled = $true
})

$form.Controls.Add($btnOpen)
$form.Controls.Add($btnSheet)
$form.Controls.Add($btnDeploy)
$form.Controls.Add($btnSlack)

# ── KPI 숫자 업데이트 헬퍼 ──
function Update-KPINum($panel, $value) {
    foreach ($ctrl in $panel.Controls) {
        if ($ctrl.Name -eq "num") {
            $ctrl.Text = $value
            break
        }
    }
}

# ── qa_status.json 읽어서 UI 업데이트 ──
function Load-StatusFile {
    try {
        if (Test-Path $statusFile) {
            $json = Get-Content $statusFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $s = $json.summary

            Update-KPINum $kpi1 $s.pc.PASS
            Update-KPINum $kpi2 $s.pc.FAIL
            Update-KPINum $kpi3 $s.pc.BLOCK
            Update-KPINum $kpi4 $s.pc.pending
            Update-KPINum $kpi5 $s.pc.NA

            $lblProgress.Text = "PC 진행률  $($s.pcRate)%"
            $clampedRate = [math]::Max(0, [math]::Min(100, [double]$s.pcRate))
            $fillW = [math]::Round($progressBg.Width * $clampedRate / 100)
            $progressFill.Size = New-Object System.Drawing.Size($fillW, 7)
            $lblDetail.Text = "$($s.pcTarget)건 중 $($s.pcDone)건 완료 | FAIL $($s.pc.FAIL)건"
            if ($s.naText) { $lblNAText.Text = $s.naText }

            $now = Get-Date -Format "HH:mm:ss"
            $lblStatus.Text = "$now 갱신"
            $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#10B981")
        }
    } catch {
        $lblStatus.Text = "갱신 실패"
        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#EF4444")
    }
}

# ── 데이터 갱신 함수 (비동기) ──
$script:refreshProc = $null
$script:pollTimer = $null

function Update-QAData {
    $lblStatus.Text = "갱신 중..."
    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#F59E0B")
    $btnRefresh.Enabled = $false
    $form.Refresh()

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "cmd.exe"
        $psi.Arguments = "/c node fetch_qa_status.js --config `"$configFullPath`""
        $psi.WorkingDirectory = $scriptDir
        $psi.CreateNoWindow = $true
        $psi.UseShellExecute = $false
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

        $script:refreshProc = [System.Diagnostics.Process]::Start($psi)

        # 완료 확인 타이머 (UI 블로킹 없음)
        $script:pollTimer = New-Object System.Windows.Forms.Timer
        $script:pollTimer.Interval = 500
        $script:pollTimer.Add_Tick({
            if ($null -ne $script:refreshProc -and $script:refreshProc.HasExited) {
                $script:pollTimer.Stop()
                $script:pollTimer.Dispose()
                $btnRefresh.Enabled = $true
                Load-StatusFile
            }
        })
        $script:pollTimer.Start()
    } catch {
        $btnRefresh.Enabled = $true
        $lblStatus.Text = "갱신 실패"
        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#EF4444")
    }
}

# ── 새로고침 버튼 ──
$btnRefresh.Add_Click({ Update-QAData })

# ── 타이머 (5분 간격) ──
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $refreshMin * 60 * 1000
$timer.Add_Tick({ Update-QAData })
$timer.Start()

# ── 드래그 이동 ──
$dragging = $false
$dragOffset = New-Object System.Drawing.Point(0, 0)

$form.Add_MouseDown({
    $script:dragging = $true
    $script:dragOffset = New-Object System.Drawing.Point($_.X, $_.Y)
})
$form.Add_MouseMove({
    if ($script:dragging) {
        $form.Location = New-Object System.Drawing.Point(
            ($form.Location.X + $_.X - $script:dragOffset.X),
            ($form.Location.Y + $_.Y - $script:dragOffset.Y)
        )
    }
})
$form.Add_MouseUp({ $script:dragging = $false })

# ── 시작 시 즉시 1회 갱신 ──
$form.Add_Shown({ Update-QAData })

# ── 실행 ──
[System.Windows.Forms.Application]::Run($form)
