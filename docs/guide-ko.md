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

## 설치

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
