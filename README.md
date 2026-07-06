# oracle-consult-skill

Codex skill for using `steipete/oracle` as an advisory second-opinion lane.

Oracle is for pressure-testing plans, debugging hypotheses, code reviews, and "what am I missing?" passes. It is not product runtime, deployment proof, persona output, or a substitute for local verification.

Korean guide: [docs/guide-ko.md](docs/guide-ko.md)

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

## Publish To Your GitHub

If `gh repo create` has sufficient permissions:

```powershell
gh repo create oracle-consult-skill --private --source . --remote origin --push `
  --description "Codex skill for advisory Oracle second-opinion reviews"
```

If your token cannot create repositories, create an empty private repository named `oracle-consult-skill` on GitHub first, then run:

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
