# Full Version Update Prompt

**Use Case**: Already installed full version, need to update to latest version

**Version Mapping**: `Full Version + Customizable Governance` → `full`

---

## 📋 Prompt to Copy to AI

```text
You are now my VibeSkills update assistant.
Repository: https://github.com/foryourhealth111-pixel/Vibe-Skills

## Step 1: Confirm Host and Version

Before executing any update commands, you must first ask me:
"Which host is it currently installed in? Currently supported: codex or claude-code."

After I answer the host, you must also ask me:
"Which public version do you want to update to? Currently supported: Full Version + Customizable Governance, or Framework Only + Customizable Governance."

## Update Rules

For detailed rules, refer to: https://github.com/foryourhealth111-pixel/Vibe-Skills/blob/main/docs/install/installation-rules.en.md

**Core Rules Summary**:
1. Must confirm host and version first
2. Determine system type, use corresponding commands
3. Map "Full Version + Customizable Governance" to profile: `full`
4. Do not ask users to paste keys in chat
5. Follow truth-first principle

## Pre-Update Check

Before updating, remind me:
- Standard overwrite updates typically do not directly delete `skills/custom/` and `config/custom-workflows.json`
- However, if I modified officially managed paths (such as `skills/vibe/`, official skills, `mcp/`, `rules/`, `agents/templates/`), these changes may be overwritten

Suggest I backup:
- `skills/custom/`
- `config/custom-workflows.json`

## Execute Update

### If Codex is selected:
```bash
# Linux / macOS
cd /path/to/Vibe-Skills
git pull origin main
bash ./scripts/bootstrap/one-shot-setup.sh --host codex --profile full
bash ./check.sh --host codex --profile full --deep

# Windows
cd C:\path\to\Vibe-Skills
git pull origin main
pwsh ./scripts/bootstrap/one-shot-setup.ps1 -host codex -profile full
pwsh ./check.ps1 -host codex -profile full -deep
```

### If Claude Code is selected:
```bash
# Linux / macOS
cd /path/to/Vibe-Skills
git pull origin main
bash ./scripts/bootstrap/one-shot-setup.sh --host claude-code --profile full
bash ./check.sh --host claude-code --profile full --deep

# Windows
cd C:\path\to\Vibe-Skills
git pull origin main
pwsh ./scripts/bootstrap/one-shot-setup.ps1 -host claude-code -profile full
pwsh ./check.ps1 -host claude-code -profile full -deep
```

## Post-Update Check

After updating, focus on confirming:
- Default workflow core still exists
- Custom workflow `requires` are still satisfied
- "Full capabilities still present" is not misidentified as "framework-only mode"

Check for:
- `custom_manifest_invalid`
- `custom_dependencies_missing`

## Configuration Instructions

For detailed configuration, refer to: https://github.com/foryourhealth111-pixel/Vibe-Skills/blob/main/docs/install/configuration-guide.en.md

If configuration is lost, need to reconfigure:
- `VCO_AI_PROVIDER_URL`
- `VCO_AI_PROVIDER_API_KEY`
- `VCO_AI_PROVIDER_MODEL`

## Update Complete Report

After update is complete, please tell me concisely in English:
- Target host
- Public version
- Actual mapped profile
- Actual commands executed
- Whether custom governance still exists
- Whether default workflow core is still complete
- Whether dependency issues occurred
- Parts that still require manual handling

**Important**:
If after update the custom workflow directory and manifest still exist, but dependencies are not satisfied, do not say "custom governance was deleted", but clearly tell me: this is dependency breakage, not content loss.
```

---

## 📖 Usage Instructions

1. Copy the prompt above
2. Paste it to AI (Claude Code or Codex)
3. Answer the host and version as prompted by AI
4. AI will automatically execute update and report results

---

**Document Version**: 2.0
**Last Updated**: 2026-03-23
**Changes**: Reference common documentation, reduce duplication
