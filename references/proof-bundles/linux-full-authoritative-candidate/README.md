# Linux Full-Authoritative Candidate Proof Bundle

This proof bundle now contains the frozen fresh-machine Linux evidence that backs the promoted `codex/linux` `full-authoritative` lane.

It is both the canonical promotion bundle and the continuing proof anchor for future no-regression checks.

## Included Artifacts

- `manifest.json`
- `docs/universalization/linux-full-authoritative-contract.md`
- `docs/universalization/platform-promotion-criteria.md`
- `docs/status/platform-promotion-baseline-2026-03-13.md`
- `docs/status/linux-pwsh-fresh-machine-evidence-ledger-2026-03-13.md`
- `linux-pwsh-run-01-wsl/`
- `linux-pwsh-run-02-docker/`

## Purpose

The bundle prevents Linux promotion work from drifting into documentation-first claims.

It keeps three things coupled:

1. current status
2. required fresh-machine evidence
3. replay/no-overclaim synchronization

## Verification

Use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify\vibe-linux-pwsh-proof-gate.ps1 -WriteArtifacts
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify\vibe-platform-promotion-bundle.ps1 -WriteArtifacts
```

The gates are now expected to pass in promoted mode, which means the proof artifacts must remain complete and the replay/docs state must stay synchronized.
