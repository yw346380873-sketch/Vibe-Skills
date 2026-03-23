# Install Path: Advanced Host / Lane Reference

> Most users should start with the two main install paths:
> - [`one-click-install-release-copy.en.md`](./one-click-install-release-copy.en.md)
> - [`manual-copy-install.en.md`](./manual-copy-install.en.md)

This document exists to explain the current real support boundary.

## Current Supported Surface

At the moment, only two hosts are supported:

- `codex`
- `claude-code`

Within that scope:

- `codex`: recommended path
- `claude-code`: preview guidance path

`TargetRoot` is only the install path.
`HostId` / `--host` is what decides host semantics.

## Recommended Commands

### Codex

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId codex
pwsh -File .\check.ps1 -HostId codex -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host codex
bash ./check.sh --host codex --profile full --deep
```

### Claude Code

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId claude-code
pwsh -File .\check.ps1 -HostId claude-code -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host claude-code
bash ./check.sh --host claude-code --profile full --deep
```

## Boundaries That Must Stay Explicit

### Codex

- this is the strongest repo-governed path today
- guidance should stay limited to local `~/.codex` settings, official MCP registration, and optional CLI dependencies
- hooks are currently frozen because of compatibility issues and are not part of the standard install path
- if Codex base online model access is needed, point users to `~/.codex/settings.json` under `env` or local environment variables for `OPENAI_API_KEY` and `OPENAI_BASE_URL`
- if the user also wants the governance AI online layer under Codex, they must additionally configure:
  - `VCO_AI_PROVIDER_URL`
  - `VCO_AI_PROVIDER_API_KEY`
  - `VCO_AI_PROVIDER_MODEL`
- `OPENAI_*` is not the same as `VCO_AI_PROVIDER_*`; the former is Codex base online provider access, while the latter is the governance AI online layer
- do not ask users to paste secrets into chat

### Claude Code

- this is preview guidance, not full closure
- hooks are currently frozen because of compatibility issues
- the installer no longer writes `settings.vibe.preview.json`
- users should open `~/.claude/settings.json` and add only the required fields under `env`
- common fields are:
  - `VCO_AI_PROVIDER_URL`
  - `VCO_AI_PROVIDER_API_KEY`
  - `VCO_AI_PROVIDER_MODEL`
- add `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN` only when needed for the host connection
- do not ask users to paste secrets into chat

## AI Governance Reminder

For both `codex` and `claude-code`, if the governance AI `url`, `apikey`, and `model` are not configured locally yet, the environment must not be described as governance-AI-online-ready.

For `codex`, that means you may describe the base online provider as ready, but you must not imply that the governance AI online layer is ready too.

Those values must be filled by the user in local host settings or local environment variables.
