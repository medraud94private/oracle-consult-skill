---
name: oracle-consult
description: Explicit advisory second-opinion workflow for Claude Code using steipete/oracle. Use when the user explicitly asks for Oracle, GPT-5.5 Pro, second opinion, external review, consult, challenge pass, counterargument, design pressure-test, or missing-risk discovery. Do not use as product runtime, deployment proof, persona output, model-verification evidence, or a substitute for local code/test verification.
disable-model-invocation: true
---

# Oracle Consult

## Overview

Use Oracle as a Claude Code-side review council: it bundles a prompt and selected files for an external model, usually ChatGPT GPT-5.5 Pro in browser mode, then returns advice that Claude Code must verify locally.

Oracle output is advisory only. It can suggest risks, alternatives, tests, and plans; it must not be treated as runtime evidence, product LLM output, server verification, or permission to mutate files.

This skill disables automatic model invocation. The user must explicitly call it as a plugin skill, usually `/oracle-consult:oracle-consult`.

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
- Treat all Oracle conclusions as hypotheses. Re-read the cited files, implement only after Claude Code judgment, and verify with local tests or documented evidence.
- API-mode Oracle runs can cost money; use browser mode or render/copy unless the user explicitly approves an API spend.
- If a browser/API run detaches or times out, inspect `oracle status` / `oracle session` before rerunning.
- Do not commit or casually share Oracle session artifacts from `$HOME/.oracle/sessions`; transcripts can contain prompt and attached-file content.

Prerequisites: Node 24+, Chrome or Chromium for browser mode, a signed-in ChatGPT account for browser mode, and explicit user approval for API mode or any paid provider route.

## Prompt Shape

Write a standalone consult prompt with:

- project and stack briefing
- exact question
- what Claude Code already checked, with errors or evidence quoted exactly
- constraints and non-goals
- requested output shape, usually "find risks, counterarguments, missing tests, and a recommended next step"

Prefer asking Oracle to challenge assumptions over asking it to decide. The user remains the decision authority; Claude Code remains responsible for implementation and verification.

## Command Patterns

Before spending tokens or launching a browser, preview the bundle:

```bash
npx -y @steipete/oracle --dry-run summary --files-report \
  -p "<standalone consult prompt>" \
  --file "path/to/key/file.py" \
  --file "path/to/docs/*.md" \
  --file "!**/.env" \
  --file "!**/*secret*"
```

If browser mode has never been initialized on this computer, run the one-time visible login setup and let the user sign in to ChatGPT in Oracle's private Chrome profile:

```bash
npx -y @steipete/oracle --engine browser --browser-manual-login \
  --browser-keep-browser \
  -p "HI" \
  --file "$HOME/.claude/skills/oracle-consult-plugin/skills/oracle-consult/SKILL.md"
```

Retry the real consult only after that profile is signed in. If the user prefers an already signed-in Chrome session, try `--browser-attach-running` instead, but treat attach failures as setup blockers rather than rerunning the same prompt repeatedly.

Preferred deep consult path:

```bash
npx -y @steipete/oracle --engine browser --model gpt-5.5-pro \
  --slug "<short-topic>" \
  -p "<standalone consult prompt>" \
  --file "path/to/key/file.py"
```

Manual fallback when automation is blocked:

```bash
npx -y @steipete/oracle --render --copy \
  -p "<standalone consult prompt>" \
  --file "path/to/key/file.py"
```

Session recovery:

```bash
npx -y @steipete/oracle status --hours 72
npx -y @steipete/oracle session <id-or-slug> --render
```

## Applying Advice

After Oracle responds, summarize only the useful findings to the user. Separate: accepted findings, rejected findings, open questions, and local verification still required. Never cite Oracle alone as proof that code is correct, complete, live, real-LLM-verified, or server-verified.
