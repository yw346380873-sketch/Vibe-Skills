# Installation Rules

This document contains the core rules that must be followed during VibeSkills installation. These rules apply to all installation prompts.

---

## 📋 Core Rules List

### Rules 1-2: Confirm Host and Version

**Rule 1**: Do not start installation until the target host is explicitly confirmed.

**Rule 2**: Do not start installation until the public version is explicitly confirmed.

**Explanation**: The installation assistant must first ask the user which host (codex or claude-code) and which version (full version or framework version) they want to install before executing any installation commands.

---

### Rules 3-4: Validate Host and Version

**Rule 3**: If the answered host is not `codex` or `claude-code`, tell the user directly: the current version does not support installation on that host yet, and stop pretending to install.

**Rule 4**: If the answered public version is not "Full Version + Customizable Governance" or "Framework Only + Customizable Governance", tell the user directly: the current public installation guide does not support that version name yet, and stop pretending to install.

**Explanation**: Only explicit host and version options are supported. Unsupported options should be clearly rejected.

---

### Rule 5: System Detection

**Rule 5**: First detect whether the current system is Windows or Linux / macOS, and use the corresponding command format.

**Explanation**:
- Linux / macOS use `bash` commands
- Windows use `pwsh` commands

---

### Rule 6: Version Mapping

**Rule 6**: Map public version names to actual profiles:
- "Full Version + Customizable Governance" → `full`
- "Framework Only + Customizable Governance" → `framework-only`

**Explanation**: Users see friendly version names, but actual installation requires mapping to technical profile names.

---

### Rules 7-8: Host-Specific Configuration

**Rule 7**: If `codex` is chosen:
- Linux / macOS use `bash ./scripts/bootstrap/one-shot-setup.sh --host codex --profile [PROFILE]`
- Then execute `bash ./check.sh --host codex --profile [PROFILE] --deep`
- Windows use corresponding `pwsh` commands
- Clearly tell the user: due to compatibility issues, the current version does not install any hooks for Codex
- Only provide recommendations around Codex's currently publicly provable local settings, MCP, and CLI dependencies

**Rule 8**: If `claude-code` is chosen:
- Linux / macOS use `bash ./scripts/bootstrap/one-shot-setup.sh --host claude-code --profile [PROFILE]`
- Then execute `bash ./check.sh --host claude-code --profile [PROFILE] --deep`
- Windows use corresponding `pwsh` commands
- Clearly tell the user: this is preview guidance only, not full closure
- Clearly tell the user: due to compatibility issues, the current version does not install hooks for Claude Code, and no longer writes `settings.vibe.preview.json`

---

### Rule 9: Key Security

**Rule 9**: For both `codex` and `claude-code`, do not ask users to paste keys, URLs, or model names directly into chat; only tell them to configure in local settings or local environment variables.

**Explanation**: Protect users' API key security and prevent sensitive information from appearing in chat history.

---

### Rule 10: Online Readiness

**Rule 10**: If local provider fields are not configured, do not describe the environment as "online readiness complete".

**Explanation**: Distinguish between "local installation complete" and "online capability ready", and do not mislead users.

---

### Rule 11: Installation Result Report

**Rule 11**: After installation completes, tell the user concisely:
- Target host
- Public version
- Actual mapped profile
- Commands actually executed
- Completed parts
- Parts still requiring manual handling

**Explanation**: Provide a clear installation result summary so users understand the current status.

---

### Rule 12: Truth-First Principle

**Rule 12**: Do not pretend that host plugins, MCP registration, or provider credentials have been automatically completed; describe missing items as optional enhancements or recommended next steps first.

**Explanation**: Follow the truth-first principle and do not exaggerate installation completeness.

---

### Rule 13: Framework Version Special Note

**Rule 13**: For the "Framework Only + Customizable Governance" version, additionally tell the user clearly: what you currently have is the governance framework foundation, which does not mean the default workflow core is already complete; if you want to integrate your own workflow later, guide the user to continue with custom workflow governed onboarding.

**Explanation**: Framework version and full version deliverables are different and need to be clearly stated.

---

## 📖 Usage

In installation prompts, you can reference these rules like this:

```text
## Installation Rules
For detailed rules, see: [Installation Rules Documentation](../installation-rules.en.md)

Core rules summary:
1. Must confirm host first (codex or claude-code)
2. Must confirm version first (full or framework)
3. Unsupported hosts/versions should be clearly rejected
4. Detect system type, use corresponding commands
5. Map version names to profiles
6-8. Execute host-specific installation commands
9. Don't let users paste keys in chat
10. Distinguish "installation complete" from "online ready"
11. Provide clear installation result report
12. Follow truth-first principle
13. Framework version needs additional explanation
```

---

**Document Version**: 1.0
**Last Updated**: 2026-03-23
