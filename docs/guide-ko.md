# oracle-consult-skill 한국어 가이드

이 저장소는 Codex가 `steipete/oracle`을 안전하게 호출하도록 돕는 Codex 스킬이다.

목표는 제품 런타임에 모델을 붙이는 것이 아니라, Codex 작업 중 어려운 설계/버그/리뷰를 외부 고성능 모델에게 한 번 더 물어보는 "second opinion" 레인을 만드는 것이다.

## 한 줄 결론

설치만 하면 Codex가 `$oracle-consult` 스킬을 읽고 사용할 수 있다. 다만 실제 GPT-5.5 Pro 컨설트 실행은 `@steipete/oracle` CLI가 필요하다.

즉:

- 스킬 설치만 있음: Codex가 안전 규칙, 프롬프트 형식, 파일 선택 기준을 사용할 수 있다.
- Oracle CLI 실행 가능: 실제 브라우저/API 컨설트까지 가능하다.
- Oracle CLI 없음: 외부 모델 호출은 안 되고, Codex가 컨설트 프롬프트를 준비하는 데까지만 의미가 있다.

이 repo가 `oracle-consult-skill`이라는 이름인 이유도 이것이다. 현재 실제 실행 백엔드가 Oracle에 강하게 의존한다. 나중에 여러 백엔드를 지원하면 `second-opinion-consult` 같은 중립 이름이 더 맞다.

## 가장 쉬운 설치

공개 repo를 받은 뒤 installer wizard를 실행한다.

```powershell
git clone https://github.com/medraud94private/oracle-consult-skill.git
cd oracle-consult-skill
.\install.ps1
```

Mac에서는 PowerShell 대신 shell installer를 쓴다.

```bash
git clone https://github.com/medraud94private/oracle-consult-skill.git
cd oracle-consult-skill
./install.sh
```

Mac에서 실제 Oracle 브라우저 컨설트까지 쓰려면 Node/npx와 Chrome이 필요하다.

```bash
brew install node
```

Oracle이 브라우저를 열면 ChatGPT 계정 로그인은 직접 해야 한다.

zip으로 내려받아서 실행 권한이 없으면 한 번만 권한을 준다.

```bash
chmod +x install.sh scripts/open-oracle-login.sh
```

추천은 리포지터리별 설치다. 그래야 실제 사용할 repo 안에서만 보이고, 다른 프로젝트에 의도치 않게 노출되지 않는다.

wizard가 처음에 언어를 묻고, 설치 범위와 설치 대상을 고르게 한다.

```text
설치 범위:
1. 추천: 현재/지정 리포지터리에만 설치
2. 사용자 전체에 설치

설치 대상:
1. 추천: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin
2. Codex만
3. Claude Code만
4. skill만
5. plugin만
6. Oracle 브라우저 로그인만 열기
```

비대화형으로 특정 repo에 한 번에 설치하려면:

```powershell
.\install.ps1 -Language ko -Preset all -Scope repo -RepoPath C:\path\to\target-repo -Force -NoPrompt
```

Mac에서는:

```bash
./install.sh --language ko --preset all --scope repo --repo-path /path/to/target-repo --force --no-prompt
```

사용자 전체에 설치하려면 `-Scope user`를 명시한다.

```powershell
.\install.ps1 -Language ko -Preset all -Scope user -Force -NoPrompt
```

Mac에서는:

```bash
./install.sh --language ko --preset all --scope user --force --no-prompt
```

repo에 설치한 뒤 바로 Oracle 브라우저 로그인까지 열고 싶으면:

```powershell
.\install.ps1 -Language ko -Preset all -Scope repo -RepoPath C:\path\to\target-repo -Force -NoPrompt -OpenOracle
```

Mac에서는:

```bash
./install.sh --language ko --preset all --scope repo --repo-path /path/to/target-repo --force --no-prompt --open-oracle
```

Oracle 로그인 열기만 따로 하고 싶으면:

```powershell
.\scripts\open-oracle-login.ps1 -Language ko
```

Mac에서는:

```bash
./scripts/open-oracle-login.sh --language ko
```

주의: ChatGPT 로그인 자체는 자동화하지 않는다. 브라우저가 열리면 사용자가 직접 로그인해야 한다. 스크립트가 자동화할 수 있는 것은 Oracle 전용 Chrome 프로필을 열고, 로그인 확인용으로 비밀이 없는 작은 임시 파일과 짧은 프롬프트를 보내는 단계까지다.

## 수동 설치

저장소를 받은 뒤 PowerShell에서 실행한다.

```powershell
cd C:\project\oracle-consult-skill
.\scripts\install-user.ps1
```

이 명령은 스킬을 현재 Codex 사용자 스킬 위치로 복사한다.

```text
$HOME\.agents\skills\oracle-consult
```

구형 Codex 환경이 `$HOME\.codex\skills`를 읽는다면 호환 설치도 가능하다.

```powershell
.\scripts\install-user.ps1 -LegacyCodexPath
```

특정 작업 저장소 안에서만 쓰고 싶으면 repo-level 설치를 사용한다.

```powershell
.\scripts\install-repo.ps1 -RepoPath C:\path\to\repo
```

그러면 아래 위치에 들어간다.

```text
<repo>\.agents\skills\oracle-consult
```

## Claude Code에서 쓰려면

Claude Code는 Codex의 `$oracle-consult` 문법을 그대로 쓰지 않는다. Claude Code에서는 skill이 slash command처럼 노출된다.

사용자 전체에 설치:

```powershell
cd C:\project\oracle-consult-skill
.\scripts\install-claude-user.ps1
```

설치 위치:

```text
$HOME\.claude\skills\oracle-consult
```

특정 repo에서만 쓰고 싶으면:

```powershell
.\scripts\install-claude-repo.ps1 -RepoPath C:\path\to\repo
```

설치 위치:

```text
<repo>\.claude\skills\oracle-consult
```

Claude Code 안에서는 이렇게 호출한다.

```text
/oracle-consult review this implementation plan for counterarguments and missing tests.
```

한국어로는:

```text
/oracle-consult 이 패치 계획 반론이랑 빠진 테스트를 봐줘. 아직 파일 수정은 하지 마.
```

Claude Code용 스킬 파일에는 아래 설정이 들어 있다.

```yaml
disable-model-invocation: true
```

즉 Claude Code가 이 스킬을 자동으로 모델 호출용으로 쓰지 않게 막고, 사용자가 `/oracle-consult`로 명시했을 때만 쓰는 구조다.

설치 후 slash command가 바로 안 보이면 Claude Code를 재시작하거나 새 세션에서 확인한다.

Claude Code용 검증:

```powershell
.\scripts\validate-claude-skill.ps1
.\scripts\smoke-claude-oracle.ps1
```

## Claude Code 플러그인으로 쓰려면

가능하다. 이 경우 standalone skill인 `/oracle-consult`가 아니라 plugin namespace가 붙은 slash command로 호출한다.

특정 repo에서만 쓰는 plugin으로 설치:

```powershell
cd C:\project\oracle-consult-skill
.\scripts\install-claude-plugin-repo.ps1 -RepoPath C:\path\to\repo
```

설치 위치:

```text
<repo>\.claude\skills\oracle-consult-plugin
```

사용자 전체에 자동 로드되는 skills-directory plugin으로 설치:

```powershell
cd C:\project\oracle-consult-skill
.\scripts\install-claude-plugin-user.ps1
```

설치 위치:

```text
$HOME\.claude\skills\oracle-consult-plugin
```

Claude Code 안에서는 이렇게 호출한다.

```text
/oracle-consult:oracle-consult review this implementation plan for counterarguments and missing tests.
```

설치하지 않고 개발 중인 plugin 폴더를 바로 테스트하려면:

```powershell
claude --plugin-dir .\claude\plugins\oracle-consult
```

Claude Code의 marketplace 흐름으로 설치하려면 이 repo를 marketplace로 추가한 뒤 plugin을 설치한다.

```text
/plugin marketplace add C:\project\oracle-consult-skill
/plugin install oracle-consult@oracle-consult-tools
```

repo 안의 Claude plugin 구조:

```text
.claude-plugin/marketplace.json
claude/plugins/oracle-consult/.claude-plugin/plugin.json
claude/plugins/oracle-consult/skills/oracle-consult/SKILL.md
```

검증:

```powershell
.\scripts\validate-claude-plugin.ps1
.\scripts\smoke-claude-plugin-oracle.ps1
```

주의: Claude Code plugin으로 설치해도 실제 GPT-5.5 Pro consult는 여전히 `@steipete/oracle` CLI가 실행한다. plugin은 공유/설치/검색을 쉽게 만드는 포장 단위다.

## 설치 후 Codex에서 어떻게 호출하나

이 스킬은 자동 호출을 꺼두었다.

```yaml
policy:
  allow_implicit_invocation: false
```

그래서 Codex가 어려운 일을 한다고 해서 몰래 Oracle에 파일을 보내지 않는다. 반드시 명시적으로 호출한다.

예:

```text
Use $oracle-consult to pressure-test this implementation plan before editing files.
```

한국어로도 이렇게 요청하면 된다.

```text
$oracle-consult 써서 이 설계안 반론이랑 빠진 테스트를 봐줘. 아직 파일 수정은 하지 말고.
```

또는:

```text
Use $oracle-consult to review this patch plan for missing risks.
```

Codex가 새로 설치한 스킬을 바로 못 보면 새 스레드를 열거나 Codex 앱/CLI를 재시작한다.

## Codex 플러그인 검색/설치로 쓰려면

가능하다. 이 경우 단순히 skill 폴더를 복사하는 것이 아니라 Codex plugin과 marketplace 구조를 쓴다.

특정 repo에만 등록하려면:

```powershell
cd C:\project\oracle-consult-skill
.\scripts\install-codex-plugin-repo.ps1 -RepoPath C:\path\to\repo
```

그러면 아래 위치에 들어간다.

```text
<repo>\.agents\plugins\plugins\oracle-consult
<repo>\.agents\plugins\marketplace.json
```

그 다음 해당 repo에서 Codex를 새로 열고 `/plugins`에서 `Oracle Consult`를 설치한다.

사용자 전체 plugin marketplace에 등록하려면:

```powershell
cd C:\project\oracle-consult-skill
.\scripts\install-codex-plugin-user.ps1
```

이 명령은 아래 두 가지를 만든다.

```text
$HOME\.agents\plugins\plugins\oracle-consult
$HOME\.agents\plugins\marketplace.json
```

그 다음 Codex에서 새 스레드를 열고 `/plugins`를 연다. 검색창에서 `Oracle Consult`를 찾아 **Install plugin**을 누르면 된다.

왜 새 스레드가 필요하냐면 Codex는 thread 시작 시점에 plugin/skill 목록을 로드하기 때문이다.

플러그인 구조는 repo 안에도 들어 있다.

```text
plugins/oracle-consult/.codex-plugin/plugin.json
plugins/oracle-consult/skills/oracle-consult/SKILL.md
.agents/plugins/marketplace.json
```

검증:

```powershell
.\scripts\validate-codex-plugin.ps1
```

주의: plugin으로 설치해도 실제 5.5 Pro consult는 여전히 `@steipete/oracle` CLI를 통해 실행된다. 플러그인은 Codex가 이 workflow를 검색/설치/호출하기 쉽게 포장한 배포 단위다.

## 실제 동작 순서

1. 사용자가 `$oracle-consult`를 명시한다.
2. Codex가 `SKILL.md`를 읽는다.
3. Codex가 독립 실행 가능한 컨설트 프롬프트를 만든다.
4. Codex가 보낼 파일/glob, 엔진, 비용/외부공유 위험을 사용자에게 보여준다.
5. 먼저 dry-run을 실행한다.

```powershell
npx -y @steipete/oracle --dry-run summary --files-report `
  -p "<standalone consult prompt>" `
  --file "path/to/key/file.py" `
  --file "path/to/docs/*.md"
```

6. 파일 목록이 안전하면 실제 browser consult를 실행한다.

```powershell
npx -y @steipete/oracle --engine browser --model gpt-5.5-pro `
  --slug "<short-topic>" `
  -p "<standalone consult prompt>" `
  --file "path/to/key/file.py"
```

7. Oracle 답변을 Codex가 다시 분류한다.

- 받아들일 내용
- 거절할 내용
- 불확실한 내용
- 로컬에서 추가 검증할 내용

8. 실제 적용은 Codex가 로컬 파일, 테스트, repo 규칙으로 확인한 뒤에만 한다.

## 첫 브라우저 로그인

브라우저 모드는 ChatGPT 로그인 세션이 필요하다. 한 번만 Oracle 전용 Chrome 프로필에 로그인한다.

```powershell
npx -y @steipete/oracle --engine browser --browser-manual-login `
  --browser-keep-browser `
  -p "HI" `
  --file "$env:USERPROFILE\.agents\skills\oracle-consult\SKILL.md"
```

브라우저가 뜨면 ChatGPT에 로그인한다. 이후에는 같은 프로필을 재사용한다.

## Oracle 패키지를 설치해야 하나

영구 설치는 필수는 아니다. 이 repo의 명령들은 보통 아래처럼 `npx`를 쓴다.

```powershell
npx -y @steipete/oracle ...
```

`npx`가 실행 시점에 패키지를 받아 실행한다. 그래서 필요한 것은 보통:

- Node.js / npx
- 네트워크
- Chrome 또는 Chromium
- browser mode용 ChatGPT 로그인

하지만 `@steipete/oracle`을 전혀 사용할 수 없는 환경이면 실제 외부 컨설트는 안 된다.

## 안전 규칙

기본적으로 보내면 안 되는 것:

- `.env`
- API key, token, cookie
- private key
- service-account 파일
- 인증 dump
- unredacted production log
- database export
- 개인 세션 transcript

항상 먼저 dry-run으로 실제 첨부 파일 목록을 본다.

```powershell
npx -y @steipete/oracle --dry-run summary --files-report ...
```

Oracle 답변은 증거가 아니다. 특히 아래를 주장할 때 Oracle만 근거로 쓰면 안 된다.

- 코드가 맞다
- 배포됐다
- 서버에서 검증됐다
- real LLM 검증이 끝났다
- 제품 런타임이 정상이다

## 검증 명령

스킬 구조 검증:

```powershell
.\scripts\validate-skill.ps1
```

Oracle dry-run smoke:

```powershell
.\scripts\smoke-oracle.ps1
```

`smoke-oracle.ps1`는 모델을 호출하지 않는다. dry-run만 한다.

네 가지 표면을 한 번에 확인하려면 아래를 실행한다.

```powershell
.\install.ps1 -Language en -Preset all -Scope repo -RepoPath C:\path\to\test-repo -Force -NoPrompt -NoOpenOracle
.\scripts\validate-skill.ps1
.\scripts\validate-claude-skill.ps1
.\scripts\validate-codex-plugin.ps1
.\scripts\validate-claude-plugin.ps1
.\scripts\smoke-oracle.ps1
.\scripts\smoke-claude-oracle.ps1
.\scripts\smoke-claude-plugin-oracle.ps1
.\scripts\open-oracle-login.ps1 -Language en -DryRun -Yes
```

Mac에서는:

```bash
./install.sh --language en --preset all --scope repo --repo-path /path/to/test-repo --force --no-prompt --no-open-oracle
./scripts/open-oracle-login.sh --language en --dry-run --yes
```

## 추천 사용 사례

좋은 사용:

- 큰 설계 변경 전 반론 요청
- 어려운 버그의 원인 가설 비교
- 큰 diff의 리뷰 압박검토
- 빠진 테스트 찾기
- 내가 놓친 위험 찾기

나쁜 사용:

- 단순 코드 수정
- 이미 테스트가 명확히 답을 주는 문제
- 비밀 파일이 필요한 문제
- 제품 런타임의 모델 호출 대체
- 검증 증거 대신 Oracle 답변을 인용
