# QA Dashboard Widget

팀 QA 현황을 실시간으로 확인하는 Windows 위젯입니다.

## 기능
- TC 결과 (PASS / FAIL / BLOCK / 미진행 / N/A) 실시간 조회
- PC 진행률 표시
- 리포트 최신화 (Vercel 배포)
- Slack 전송

---

## 팀원 셋업 가이드

### 1단계: 사전 설치

| 도구 | 설치 방법 |
|------|----------|
| Node.js | https://nodejs.org (LTS 버전) |
| Vercel CLI | `npm install -g vercel` 후 `vercel login` |

### 2단계: 파일 준비 (팀장에게 받을 것)

아래 파일을 팀장에게 받아 지정 위치에 넣으세요.

| 파일 | 저장 위치 | 설명 |
|------|----------|------|
| `client_secret.json` | `credentials/` | Google OAuth 앱 키 |
| Slack Bot Token | - | `xoxb-...` 형태 문자열 |

### 3단계: 개인 설정 파일 생성

**scripts/jira_config.json** (본인 Jira 계정으로)
```json
{ "email": "본인@이메일.com", "token": "본인_Atlassian_API_토큰" }
```
> Atlassian API 토큰 발급: https://id.atlassian.com/manage-profile/security/api-tokens

**scripts/slack_config.json** (팀장에게 토큰 받아서)
```json
{ "token": "xoxb-받은-토큰" }
```

**scripts/vercel_config.json** (팀장에게 토큰 받아서)
```json
{ "token": "받은-Vercel-토큰" }
```
> Vercel 토큰은 팀장에게 메신저로 요청하세요. GitHub에 올리지 마세요.

**config/qa_config_6차.json** 수정
```json
"deployDir": "C:/Users/본인이름/Downloads/qa-report-deploy",
"htmlTemplate": "C:/Users/본인이름/Downloads/QA_결과서/QA_테스트_결과서_5차_template.html"
```

### 4단계: 셋업 확인

PowerShell에서 실행:
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1
```
모든 항목이 OK가 될 때까지 안내에 따라 설정하세요.

### 5단계: Google 최초 인증 (최초 1회만)

```powershell
node scripts/google_auth.js
```
브라우저에서 Google 로그인 후 완료. 이후 자동 인증.

### 6단계: 위젯 실행

```powershell
powershell -ExecutionPolicy Bypass -File qa-widget.ps1
```

---

## 새 차수 추가 (7차, 8차...)

1. `config/qa_config_template.json` 복사 → `config/qa_config_7차.json`
2. 내용 수정 (milestone, spreadsheetId, reportUrl, jiraSprintName, statusFile, 로컬 경로)
3. 위젯 실행 시 파라미터 변경:
   ```powershell
   powershell -ExecutionPolicy Bypass -File qa-widget.ps1 -ConfigFile qa_config_7차.json
   ```

---

## 파일 구조

```
qa-dashboard-widget/
├── qa-widget.ps1           # 위젯 본체
├── setup.ps1               # 팀원 셋업 확인 스크립트
├── config/
│   ├── qa_config_6차.json  # 6차 설정
│   └── qa_config_template.json  # 새 차수 템플릿
├── scripts/
│   ├── fetch_qa_status.js  # TC 데이터 조회
│   ├── update_report.js    # 리포트 HTML 생성
│   ├── send_slack_qa.js    # Slack 전송
│   ├── google_auth.js      # Google OAuth
│   ├── slack_config.json   # ← 팀장에게 받아서 생성 (gitignore)
│   ├── vercel_config.json  # ← 팀장에게 받아서 생성 (gitignore)
│   └── jira_config.json    # ← 본인이 생성 (gitignore)
├── credentials/
│   ├── client_secret.json  # ← 팀장에게 받아서 저장 (gitignore)
│   └── oauth_token.json    # ← 최초 인증 후 자동 생성 (gitignore)
└── tools/
    ├── fix_encoding.ps1
    └── create_shortcut.ps1
```
