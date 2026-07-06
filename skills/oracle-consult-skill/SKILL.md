---
name: oracle-consult-skill
description: Use steipete/oracle from Codex as an explicit standalone advisory second-opinion lane for hard debugging, architecture tradeoffs, implementation plans, code-review pressure testing, regression-risk searches, and "what am I missing?" improvement passes. Use when the user asks for Oracle, GPT-5.5 Pro, 5.5 Pro, second opinion, external review, consult, challenge pass, counterargument, design pressure-test, or Codex-side thinking improvement. Do not use as product runtime, deployment proof, persona output, model-verification evidence, or a substitute for local code/test verification.
---

# Oracle Consult

## Overview

Use Oracle as a Codex-side review council: it bundles a prompt and selected files for an external model, usually ChatGPT GPT-5.5 Pro in browser mode, then returns advice that Codex must verify locally.

Oracle output is advisory only. It can suggest risks, alternatives, tests, and plans; it must not be treated as runtime evidence, product LLM output, server verification, or permission to mutate files.

## Consult Decision

Use Oracle when the task benefits from an independent high-capacity pass:

- non-trivial design or implementation tradeoffs
- difficult bugs after local investigation has real evidence
- code review before a risky patch or after a large diff
- plan pressure-testing, counterarguments, or missing-test discovery
- "stuck" moments where another model may find a better hypothesis

Skip Oracle for routine edits, simple lookups, tasks where local files/tests already decide the answer, or anything requiring secrets or live production mutation.

## Safety Rules

- Keep Oracle outside product runtime, persona output, deployment proof, and model-verification claims.
- Do not attach secrets by default: `.env`, credentials, tokens, cookies, private keys, service-account files, auth dumps, unredacted logs, database dumps, or session transcripts.
- Send the minimum file set that contains the truth. Prefer exact files and tight globs over whole-repo bundles.
- Before any browser or API consult, show the user the exact prompt, files/globs, engine, and cost/disclosure implications unless they already explicitly requested Oracle and the file set is non-sensitive.
- Always run `--dry-run summary --files-report` before browser/API consults and inspect the resolved files.
- Treat all Oracle conclusions as hypotheses. Re-read the cited files, implement only after Codex judgment, and verify with local tests or documented evidence.
- API-mode Oracle runs can cost money; use browser mode or render/copy unless the user explicitly approves an API spend.
- If a browser/API run detaches or times out, inspect `oracle status` / `oracle session` before rerunning.
- Do not commit or casually share Oracle session artifacts from `$env:USERPROFILE\.oracle\sessions`; transcripts can contain prompt and attached-file content.

Prerequisites: Node 24+, Chrome or Chromium for browser mode, a signed-in ChatGPT account for browser mode, and explicit user approval for API mode or any paid provider route.

## Local Configuration

Read `oracle-consult.config.json` next to this `SKILL.md` before building Oracle commands. Defaults:

- `browserMode: "hidden"`: launch Oracle browser mode with `--browser-hide-window`.
- `browserMode: "attach"`: use `--browser-attach-running` to attach to an already-running Chrome with DevTools access; do not combine it with `--browser-hide-window`, `--browser-manual-login`, or `--browser-keep-browser`.
- `browserMode: "visible"`: launch browser mode without hiding; use for debugging.
- `browserMode: "render"`: use `--render --copy` and ask the user to paste into ChatGPT manually.

Treat `sessionPolicy: "fresh-by-default"` literally. Start each consult as a fresh Oracle run unless the user explicitly asks to follow up on a prior Oracle session. Do not use `oracle --followup`, `oracle restart`, `oracle session --live`, or `oracle session --harvest` as the default path.

## Prompt Shape

Write a standalone consult prompt with:

- project and stack briefing
- exact question
- what Codex already checked, with errors or evidence quoted exactly
- constraints and non-goals
- requested output shape, usually "find risks, counterarguments, missing tests, and a recommended next step"

Prefer asking Oracle to challenge assumptions over asking it to decide. The user remains the decision authority; Codex remains responsible for implementation and verification.

## Command Patterns

Before spending tokens or launching a browser, preview the bundle:

```powershell
npx -y @steipete/oracle --dry-run summary --files-report `
  -p "<standalone consult prompt>" `
  --file "path/to/key/file.py" `
  --file "path/to/docs/*.md" `
  --file "!**/.env" `
  --file "!**/*secret*"
```

If browser mode has never been initialized on this computer, run the one-time visible login setup and let the user sign in to ChatGPT in Oracle's private Chrome profile:

```powershell
npx -y @steipete/oracle --engine browser --browser-manual-login `
  --browser-keep-browser `
  -p "HI" `
  --file "$env:USERPROFILE\.agents\skills\oracle-consult-skill\SKILL.md"
```

Retry the real consult only after that profile is signed in. The login step must be visible because the user signs in manually. For normal consults after login, use the browser mode from `oracle-consult.config.json`. The default `hidden` mode adds `--browser-hide-window`; if the user dislikes any launched window, switch config to `attach` and use `--browser-attach-running` with a DevTools-enabled Chrome. Treat attach failures as setup blockers rather than rerunning the same prompt repeatedly.

Preferred deep consult path when config `browserMode` is `hidden`:

```powershell
npx -y @steipete/oracle --engine browser --model gpt-5.5-pro `
  --browser-hide-window `
  --browser-archive never `
  --slug "<short-topic>" `
  -p "<standalone consult prompt>" `
  --file "path/to/key/file.py"
```

Preferred path when config `browserMode` is `attach`:

```powershell
npx -y @steipete/oracle --engine browser --model gpt-5.5-pro `
  --browser-attach-running `
  --browser-archive never `
  --slug "<short-topic>" `
  -p "<standalone consult prompt>" `
  --file "path/to/key/file.py"
```

Manual fallback when automation is blocked:

```powershell
npx -y @steipete/oracle --render --copy `
  -p "<standalone consult prompt>" `
  --file "path/to/key/file.py"
```

Session recovery is a one-attempt retrieval path, not the default consult path. If recovery errors, stop recovery and start a fresh consult with the same standalone prompt:

```powershell
npx -y @steipete/oracle status --hours 72
npx -y @steipete/oracle session <id-or-slug> --render
```

## Applying Advice

After Oracle responds, summarize only the useful findings to the user. Separate: accepted findings, rejected findings, open questions, and local verification still required. Never cite Oracle alone as proof that code is correct, complete, live, real-LLM-verified, or server-verified.

## Portable Distribution

If this workflow is promoted into a separate Git-managed methodology, keep the install unit as a plain Codex skill first:

- User-level install: copy the `oracle-consult-skill` folder into `$env:USERPROFILE\.agents\skills\oracle-consult-skill` for current Codex skill discovery. Some setups also support `$env:USERPROFILE\.codex\skills\oracle-consult-skill`; keep that as a compatibility option.
- Repo-level install: copy the folder into `<repo>\.agents\skills\oracle-consult-skill`.
- Keep `SKILL.md` as the required skill file and `agents/openai.yaml` as the recommended UI/policy metadata file.
- Add installer scripts only outside the skill folder, for example `scripts/install-user.ps1` and `scripts/install-repo.ps1`, so the skill itself stays lean.
- Package as a Codex plugin later only if it needs bundled MCP config, app integrations, marketplace metadata, or multiple coordinated skills.
