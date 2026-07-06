# oracle-consult-skill

Codex skill for using `steipete/oracle` as an advisory second-opinion lane.

Oracle is for pressure-testing plans, debugging hypotheses, code reviews, and "what am I missing?" passes. It is not product runtime, deployment proof, persona output, or a substitute for local verification.

Korean guide: [docs/guide-ko.md](docs/guide-ko.md)

## Quick Start

Clone the public repository, then run the installer wizard:

```powershell
git clone https://github.com/medraud94private/oracle-consult-skill.git
cd oracle-consult-skill
.\install.ps1
```

The wizard lets you choose a language, install target, and whether to open Oracle's browser login setup.

Non-interactive recommended install:

```powershell
.\install.ps1 -Language ko -Preset all -Force -NoPrompt
```

Install everything and immediately open Oracle's ChatGPT login setup:

```powershell
.\install.ps1 -Language ko -Preset all -Force -NoPrompt -OpenOracle
```

Open only Oracle's browser login setup:

```powershell
.\scripts\open-oracle-login.ps1 -Language ko
```

Oracle login cannot be fully automated because the user must sign in to ChatGPT manually. The script can open Oracle's persistent Chrome profile, keep the browser open, and send only a harmless setup-check prompt after you approve it.

## Does It Require Oracle?

Yes for the main workflow. This skill is a Codex instruction wrapper around the `@steipete/oracle` CLI. Without Oracle installed or runnable through `npx`, Codex can still read the skill's safety rules and prompt patterns, but it cannot perform the actual GPT-5.5 Pro consult.

That is why the repo and skill use the `oracle-consult` name. If this later supports multiple consult backends, a better name would be `second-opinion-consult`, with Oracle as one provider.

## How Codex Calls It

After installation, ask Codex explicitly:

```text
Use $oracle-consult to pressure-test this implementation plan before we edit files.
```

The skill is configured with `allow_implicit_invocation: false`, so Codex should not silently use it just because a task is hard. This avoids accidental external disclosure. A real consult should follow this shape:

1. Codex drafts a standalone consult prompt.
2. Codex shows the exact prompt, files/globs, engine, and disclosure/cost implications.
3. Codex runs `npx -y @steipete/oracle --dry-run summary --files-report ...`.
4. After approval or an already-explicit Oracle request, Codex runs browser mode, API mode, or render/copy.
5. Codex classifies Oracle's answer as accepted, rejected, or uncertain, then verifies locally before applying anything.

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

Claude Code user-level install:

```powershell
.\scripts\install-claude-user.ps1
```

Claude Code repo-level install:

```powershell
.\scripts\install-claude-repo.ps1 -RepoPath C:\path\to\repo
```

In Claude Code, invoke it as a slash command:

```text
/oracle-consult review this patch plan for missing risks
```

Claude Code plugin install:

```powershell
.\scripts\install-claude-plugin-user.ps1
```

In Claude Code, invoke the plugin skill with its namespace:

```text
/oracle-consult:oracle-consult review this patch plan for missing risks
```

For local plugin development without installing:

```powershell
claude --plugin-dir .\claude\plugins\oracle-consult
```

For marketplace-style install in Claude Code, add this repo as a marketplace and install the plugin:

```text
/plugin marketplace add C:\project\oracle-consult-skill
/plugin install oracle-consult@oracle-consult-tools
```

Codex plugin directory install/search flow:

```powershell
.\scripts\install-codex-plugin-user.ps1
```

Then start a new Codex thread, open `/plugins`, search for **Oracle Consult**, and choose **Install plugin**. This uses the personal marketplace at `$HOME\.agents\plugins\marketplace.json`.

## Validate

```powershell
.\install.ps1 -Language en -Preset all -Force -NoPrompt -NoOpenOracle
.\scripts\validate-skill.ps1
.\scripts\smoke-oracle.ps1
.\scripts\validate-claude-skill.ps1
.\scripts\smoke-claude-oracle.ps1
.\scripts\validate-codex-plugin.ps1
.\scripts\validate-claude-plugin.ps1
.\scripts\smoke-claude-plugin-oracle.ps1
.\scripts\open-oracle-login.ps1 -Language en -DryRun -Yes
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

## Publish To Your GitHub

If `gh repo create` has sufficient permissions:

```powershell
gh repo create oracle-consult-skill --public --source . --remote origin --push `
  --description "Codex skill for advisory Oracle second-opinion reviews"
```

If your token cannot create repositories, create an empty public or private repository named `oracle-consult-skill` on GitHub first, then run:

```powershell
git remote add origin https://github.com/<owner>/oracle-consult-skill.git
git push -u origin main
```

## Operating Rule

Before a real browser/API consult, show the user:

- exact prompt
- exact files/globs
- engine (`browser`, `api`, or `render/copy`)
- cost or disclosure implications

Always run `--dry-run summary --files-report` first. Treat Oracle output as advice, then re-read files and verify locally.
