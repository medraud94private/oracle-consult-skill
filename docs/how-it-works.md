# How It Works

`oracle-consult` is a workflow package, not a model provider.

The package does not contain GPT-5.5 Pro access by itself. It teaches Codex or Claude Code when and how to call `steipete/oracle`, which then bundles a prompt plus selected files and sends them through one of Oracle's engines.

## Layers

1. **Agent-facing wrapper**
   - Codex skill: `skills/oracle-consult/SKILL.md`
   - Claude Code skill: `claude/skills/oracle-consult/SKILL.md`
   - Codex plugin: `plugins/oracle-consult/`
   - Claude Code plugin: `claude/plugins/oracle-consult/`

2. **Oracle CLI**: `npx -y @steipete/oracle ...`
   - Expands file globs.
   - Creates the prompt/file bundle.
   - Runs browser mode, API mode, or render/copy.
   - Stores sessions under `$HOME/.oracle/sessions`.

3. **External model surface**
   - Usually ChatGPT browser mode with GPT-5.5 Pro.
   - API mode is possible but should require explicit cost approval.

4. **Local agent verification**
   - Re-read local files.
   - Apply only the advice that survives local judgment.
   - Run local tests or documented checks.
   - Never cite Oracle alone as proof of correctness.

## Supported Install Shapes

| Shape | Source path | Install command | Invocation |
| --- | --- | --- | --- |
| Codex skill | `skills/oracle-consult/` | `.\scripts\install-user.ps1` | `$oracle-consult` |
| Claude Code skill | `claude/skills/oracle-consult/` | `.\scripts\install-claude-user.ps1` | `/oracle-consult` |
| Codex plugin | `plugins/oracle-consult/` | `.\scripts\install-codex-plugin-user.ps1`, then install from `/plugins` | `$oracle-consult` after plugin install |
| Claude Code plugin | `claude/plugins/oracle-consult/` | `.\scripts\install-claude-plugin-user.ps1` or marketplace install | `/oracle-consult:oracle-consult` |

The wrapper shape changes discovery and invocation. It does not change the actual consult backend: real GPT-5.5 Pro consults still go through `@steipete/oracle`.

## Wrapper Responsibilities

Each wrapper:

- Decides when a second opinion is appropriate.
- Requires dry-run file reporting.
- Disables implicit invocation where the host supports it.
- Tells the host agent to treat Oracle output as advisory.

## Dependency

The main workflow requires Oracle. If Oracle is unavailable, the wrappers can still help draft a consult prompt or choose a safe file set, but they cannot get the external model's answer.

This is a hard enough dependency that `oracle-consult-skill` is the clearest name today.

If this grows into a provider-neutral framework, rename or supersede it with something like:

- `second-opinion-consult`
- `codex-consult-lane`
- `external-review-council`

In that future shape, Oracle would become one backend among several.

## Invocation

Use explicit invocation:

```text
Use $oracle-consult to review this patch plan for missing risks.
/oracle-consult review this patch plan for missing risks.
/oracle-consult:oracle-consult review this patch plan for missing risks.
```

Avoid vague requests such as "think harder" when you mean Oracle. These wrappers intentionally avoid implicit external file sharing.

## Typical Command Flow

Dry-run first:

```powershell
npx -y @steipete/oracle --dry-run summary --files-report `
  -p "<standalone consult prompt>" `
  --file "src/key-file.ts" `
  --file "docs/plan.md"
```

Browser consult:

```powershell
npx -y @steipete/oracle --engine browser --model gpt-5.5-pro `
  --slug "<short-topic>" `
  -p "<standalone consult prompt>" `
  --file "src/key-file.ts" `
  --file "docs/plan.md"
```

Manual fallback:

```powershell
npx -y @steipete/oracle --render --copy `
  -p "<standalone consult prompt>" `
  --file "src/key-file.ts" `
  --file "docs/plan.md"
```
