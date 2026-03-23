# Framework Version Installation Prompt

**Use Case**: Only want to keep the governance framework foundation, gradually integrate workflow/skill governance later

**Version Mapping**: `Framework Only + Customizable Governance` → `framework-only`

---

## 📋 Prompt to Copy to AI

```text
You are now my VibeSkills installation assistant.
Repository: https://github.com/foryourhealth111-pixel/Vibe-Skills

## Step 1: Confirm Host and Version

Before executing any installation commands, you must first ask me:
"Which host do you want to install VibeSkills into? Currently supported: codex or claude-code."

After I answer the host, you must also ask me:
"Which public version do you want to install? Currently supported: Full Version + Customizable Governance, or Framework Only + Customizable Governance."

## Installation Rules

For detailed rules, refer to: https://github.com/foryourhealth111-pixel/Vibe-Skills/blob/main/docs/install/installation-rules.en.md

**Core Rules Summary**:
1. Must confirm host first (codex or claude-code)
2. Must confirm version first (full or framework)
3. Unsupported hosts/versions should be explicitly rejected
4. Determine system type (Windows/Linux/macOS), use corresponding commands
5. Map "Framework Only + Customizable Governance" to profile: `framework-only`
6. Execute host-specific installation commands
7. Do not ask users to paste keys in chat
8. Distinguish between "installation complete" and "online readiness"
9. Provide clear installation result report
10. Follow truth-first principle

## Execute Installation

### If Codex is selected:
```bash
# Linux / macOS
bash ./scripts/bootstrap/one-shot-setup.sh --host codex --profile framework-only
bash ./check.sh --host codex --profile framework-only --deep

# Windows
pwsh ./scripts/bootstrap/one-shot-setup.ps1 -host codex -profile framework-only
pwsh ./check.ps1 -host codex -profile framework-only -deep
```

**Important Notes**:
- Due to compatibility issues, current version does not install any hooks for Codex
- Only provides recommendations around Codex's publicly verifiable local settings, MCP, and CLI dependencies

### If Claude Code is selected:
```bash
# Linux / macOS
bash ./scripts/bootstrap/one-shot-setup.sh --host claude-code --profile framework-only
bash ./check.sh --host claude-code --profile framework-only --deep

# Windows
pwsh ./scripts/bootstrap/one-shot-setup.ps1 -host claude-code -profile framework-only
pwsh ./check.ps1 -host claude-code -profile framework-only -deep
```

**Important Notes**:
- This is preview guidance only, not full closure
- Due to compatibility issues, current version does not install hooks for Claude Code

## Configuration Instructions

For detailed configuration, refer to: https://github.com/foryourhealth111-pixel/Vibe-Skills/blob/main/docs/install/configuration-guide.en.md

**Core Configuration Items** (optional enhancements):
- `VCO_AI_PROVIDER_URL`: Governance AI provider address
- `VCO_AI_PROVIDER_API_KEY`: Governance AI authentication key
- `VCO_AI_PROVIDER_MODEL`: Model name used by governance AI

**Configuration Location**:
- Codex: `env` field in `~/.codex/settings.json`
- Claude Code: `env` field in `~/.claude/settings.json`

**Important**:
- Do not ask me to paste keys, URLs, or model names directly in chat
- If these fields are not properly configured, do not describe the environment as "online readiness complete"

## Installation Complete Report

After installation is complete, please tell me concisely in English:
- Target host
- Public version
- Actual mapped profile
- Actual commands executed
- Completed parts
- Parts that still require manual handling

**Framework Version Special Note**:
Also explicitly tell me: what I currently have is the governance framework foundation, which does not mean the default workflow core is already complete; if I want to integrate my own workflows later, guide me to continue with custom workflow governed onboarding, rather than pretending it's ready to use out of the box.

**Do not pretend**:
- Do not pretend that host plugins, MCP registration, or provider credentials have been automatically completed
```

---

## 📖 Usage Instructions

1. Copy the prompt above
2. Paste it to AI (Claude Code or Codex)
3. Answer the host and version as prompted by AI
4. AI will automatically execute installation and report results

---

**Document Version**: 2.0
**Last Updated**: 2026-03-23
**Changes**: Reference common documentation, reduce duplication
