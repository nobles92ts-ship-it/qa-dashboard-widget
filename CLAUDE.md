# CLAUDE.md — QA Dashboard Widget 설치 가이드 (에이전트용)

이 저장소는 **팀 QA 현황 실시간 위젯**(Windows PowerShell + Node.js)입니다.
사용자가 이 레포 링크를 주며 "세팅해줘 / 설치해줘"라고 하면, 아래 순서대로 **먼저 환경을 점검한 뒤** 진행하세요. (사람용 상세 가이드는 `README.md`)

## 원칙
- **비밀정보(토큰·키·client_secret)는 절대 출력하거나 커밋하지 마세요.** `.gitignore`로 제외돼 있습니다.
- Windows 전제. 명령은 PowerShell로 실행합니다.

## STEP 1 — 먼저 환경 점검 (비대화형, 반드시 먼저)
```powershell
powershell -ExecutionPolicy Bypass -File setup.ps1 -Check
```
- Node.js / Vercel CLI / Google 인증(`credentials/client_secret.json`, `oauth_token.json`) / `scripts/slack_config.json` / `vercel_config.json` / `jira_config.json` 을 점검하고 **PASS/FAIL 만 출력**합니다. 질문·실행·바로가기 생성 없음. **종료코드 0=통과 / 1=실패.**
- FAIL 항목이 있으면 사용자에게 무엇을 준비할지 안내하세요:
  | 없는 항목 | 안내 |
  |-----------|------|
  | `credentials/client_secret.json`, Slack 봇 토큰, Vercel 토큰 | **팀장에게 요청** (메신저) |
  | `oauth_token.json` | `node scripts/google_auth.js` 실행 → 브라우저 최초 인증(1회) |
  | `scripts/jira_config.json` | 본인 Atlassian 이메일 + API 토큰 (`https://id.atlassian.com/manage-profile/security/api-tokens`) |
  | Node.js / Vercel CLI | `https://nodejs.org` 설치 / `npm install -g vercel && vercel login` |
- 점검이 통과할 때까지 위를 반복 안내하세요.

## STEP 2 — 차수 선택
- `config/` 의 `qa_config_*차.json`(단, `qa_config_template.json` 제외)이 설치 가능한 차수입니다. 목록을 만들어 사용자에게 **"몇 차를 설치할까요? (예: 5·6·7차)"** 라고 물어보세요.
- 사용자가 고른 차수의 파일명을 `qa_config_<N>차.json` 형태로 확정합니다.

## STEP 3 — 실행 / 설치 마무리
- 선택한 차수로 위젯 실행:
  ```powershell
  powershell -ExecutionPolicy Bypass -File qa-widget.ps1 -ConfigFile qa_config_<N>차.json
  ```
- 사용자가 "매번 실행이 번거롭다"고 하면 바탕화면 바로가기를 안내:
  - 대화형 설치(선택→점검→바로가기→실행): `powershell -File setup.ps1`
  - 5·6·7차 바로가기 한 번에: `powershell -File tools/create_shortcut.ps1`

## 주의
- config의 `deployDir`·`htmlTemplate` 가 `YOUR_NAME` placeholder면 "리포트 최신화(배포)" 버튼용이니 사용자 본인 경로로 수정하도록 안내하세요. **위젯 조회 자체에는 불필요.**
- 각 차수 구글 시트의 **열람 권한이 사용자 계정에 있어야** 데이터가 표시됩니다.
