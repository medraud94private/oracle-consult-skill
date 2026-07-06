# How It Works

`oracle-consult` is a Codex skill, not a model provider.

The skill does not contain GPT-5.5 Pro access by itself. It teaches Codex when and how to call `steipete/oracle`, which then bundles a prompt plus selected files and sends them through one of Oracle's engines.

## Layers

1. **Codex skill**: `skills/oracle-consult/SKILL.md`
   - Decides when a second opinion is appropriate.
   - Requires dry-run file reporting.
   - Blocks implicit invocation via `agents/openai.yaml`.
   - Tells Codex to treat Oracle output as advisory.

2. **Oracle CLI**: `npx -y @steipete/oracle ...`
   - Expands file globs.
   - Creates the prompt/file bundle.
   - Runs browser mode, API mode, or render/copy.
   - Stores sessions under `$HOME/.oracle/sessions`.

3. **External model surface**
   - Usually ChatGPT browser mode with GPT-5.5 Pro.
   - API mode is possible but should require explicit cost approval.

4. **Codex verification**
   - Re-read local files.
   - Apply only the advice that survives local judgment.
   - Run local tests or documented checks.
   - Never cite Oracle alone as proof of correctness.

## Dependency

The main workflow requires Oracle. If Oracle is unavailable, the skill can still help Codex draft a consult prompt or choose a safe file set, but it cannot get the external model's answer.

This is a hard enough dependency that `oracle-consult-skill` is the clearest name today.

If this grows into a provider-neutral framework, rename or supersede it with something like:

- `second-opinion-consult`
- `codex-consult-lane`
- `external-review-council`

In that future shape, Oracle would become one backend among several.

## Codex Invocation

Use explicit invocation:

```text
Use $oracle-consult to review this patch plan for missing risks.
```

Avoid vague requests such as "think harder" when you mean Oracle, because this skill intentionally disables implicit invocation to prevent accidental external file sharing.

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

