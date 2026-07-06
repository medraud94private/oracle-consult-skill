# Oracle Consult Claude Code Plugin

This plugin packages the `oracle-consult` Claude Code skill for namespaced plugin use.

Load locally while developing:

```powershell
claude --plugin-dir .\claude\plugins\oracle-consult
```

Invoke inside Claude Code:

```text
/oracle-consult:oracle-consult review this plan for missing risks
```

Install as a skills-directory plugin:

```powershell
.\scripts\install-claude-plugin-user.ps1
```

Validate:

```powershell
.\scripts\validate-claude-plugin.ps1
```

Real consults still require `npx -y @steipete/oracle`, browser/API setup, and the disclosure rules in the bundled skill.
