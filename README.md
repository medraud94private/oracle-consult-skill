# oracle-consult-skill

Codex skill for using `steipete/oracle` as an advisory second-opinion lane.

Oracle is for pressure-testing plans, debugging hypotheses, code reviews, and "what am I missing?" passes. It is not product runtime, deployment proof, persona output, or a substitute for local verification.

## Install

User-level install, current Codex skill location:

```powershell
.\scripts\install-user.ps1
```

Compatibility install for Codex setups that still read `$HOME\.codex\skills`:

```powershell
.\scripts\install-user.ps1 -LegacyCodexPath
```

Repo-level install into a workspace:

```powershell
.\scripts\install-repo.ps1 -RepoPath C:\path\to\repo
```

## Validate

```powershell
.\scripts\validate-skill.ps1
.\scripts\smoke-oracle.ps1
```

`smoke-oracle.ps1` uses `--dry-run`; it does not call a model.

## Browser Setup

For browser mode, sign in once to Oracle's private ChatGPT profile:

```powershell
npx -y @steipete/oracle --engine browser --browser-manual-login `
  --browser-keep-browser `
  -p "HI" `
  --file "$env:USERPROFILE\.agents\skills\oracle-consult\SKILL.md"
```

Then run consults with explicit prompts and tight file sets.

## Operating Rule

Before a real browser/API consult, show the user:

- exact prompt
- exact files/globs
- engine (`browser`, `api`, or `render/copy`)
- cost or disclosure implications

Always run `--dry-run summary --files-report` first. Treat Oracle output as advice, then re-read files and verify locally.

