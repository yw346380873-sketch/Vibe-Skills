# Deployment

## Profiles

- `minimal`: install only required bundled skills + rules + hooks
- `full`: install required + recommended bundled skills + MCP templates

## Windows

```powershell
pwsh -File .\install.ps1 -Profile minimal
pwsh -File .\install.ps1 -Profile full -InstallExternal
```

## Verification

```powershell
pwsh -File .\check.ps1 -Profile full
```

## External Tools

`-InstallExternal` optionally installs external tools/plugins when available:
- SuperClaude command set
- claude-flow (npm global)
- plugin entries in manifest (best-effort)

## Safe Update Flow

1. Pull latest `vco-skills-codex`
2. Run `scripts/bootstrap/sync-local-compat.ps1`
3. Review diff
4. Run `check.ps1`
5. Commit + push
