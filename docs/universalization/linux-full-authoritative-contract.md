# Linux Full-Authoritative Contract

> Status baseline: 2026-03-13  
> Scope: define what must remain true now that Linux has been promoted to `full-authoritative` when `pwsh` is available.

## Purpose

This contract freezes the acceptance standard for Linux promotion.

It exists to prevent two failure modes:

1. documentation upgrades that run ahead of proof
2. shell-path convenience improvements being misread as authoritative closure

Linux is now `full-authoritative` when `pwsh` is available.
This document now acts as the contract that must remain true to preserve that claim.

## Current Truth

As of this baseline:

- Windows remains a proven `full-authoritative` lane.
- `Codex on Linux + pwsh` is now `full-authoritative`.
- `Codex on Linux without pwsh` remains `degraded-but-supported`.
- Runtime-neutral freshness, coherence, and bootstrap-doctor cores now exist as part of a finished promotion proof for the Linux + `pwsh` lane.

## Promotion Target

Linux may remain promoted to `full-authoritative` only while **all** of the following remain simultaneously true:

1. `install.sh` completes the authoritative validation path without requiring `pwsh`.
2. `check.sh --profile full --deep` runs freshness, coherence, and bootstrap-doctor semantics on Linux without silent skips.
3. The runtime-neutral path emits machine-readable receipts with stable schema and stable pass/fail meaning.
4. Windows PowerShell remains green on the original authority lane.
5. Replay fixtures, platform contracts, and public support docs remain synchronized to the frozen evidence.

## Required Entry Points

Linux promotion depends on these surfaces:

- `install.sh`
- `check.sh`
- `scripts/bootstrap/one-shot-setup.sh`
- `scripts/verify/runtime_neutral/freshness_gate.py`
- `scripts/verify/runtime_neutral/coherence_gate.py`
- `scripts/verify/runtime_neutral/bootstrap_doctor.py`

These are allowed to evolve only inside the governed migration window recorded in:

- `config/official-runtime-main-chain-policy.json`

## Required Receipts and Evidence

Promotion requires fresh evidence for:

- runtime freshness result
- release/install/runtime coherence result
- bootstrap doctor result
- Linux degraded-lane honesty when `pwsh` is absent
- Windows baseline preservation during the same migration batch

The minimum proof commands are:

```powershell
python tests/runtime_neutral/test_freshness_gate.py
python tests/runtime_neutral/test_bootstrap_doctor.py
python tests/runtime_neutral/test_coherence_gate.py
bash -n install.sh
bash -n check.sh
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify\vibe-cross-host-install-isolation-gate.ps1 -WriteArtifacts
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify\vibe-universalization-no-regression-gate.ps1 -WriteArtifacts
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify\vibe-platform-support-contract-gate.ps1 -WriteArtifacts
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify\vibe-release-install-runtime-coherence-gate.ps1 -WriteArtifacts
```

Fresh-machine Linux proof is frozen and promotion is now closed, but any future drift must be treated as a promotion regression.

## Stop Rules

The migration must stop and stay below `full-authoritative` if any of the following happens:

1. Windows baseline regresses.
2. Runtime-neutral receipts drift from existing contract semantics.
3. Linux without `pwsh` becomes a silent skip instead of an explicit degraded result.
4. Public docs claim promotion before replay fixtures and platform contracts are updated.
5. The install-isolation gate detects unapproved main-chain edits outside the active change window.

## Current Closure State

The original blockers are now closed:

1. `adapters/codex/platform-linux.json` now declares `full-authoritative`.
2. `tests/replay/fixtures/host-capability-matrix.json` now allows `codex/linux` as `full-authoritative`.
3. `docs/universalization/platform-support-matrix.md` and `docs/universalization/platform-parity-contract.md` now describe Linux + `pwsh` as promoted while preserving the degraded `without_pwsh` lane.
4. Replay fixtures, manifest state, adapter state, and public wording are synchronized to the promoted Linux lane.

## Allowed Current Claim

The strongest truthful claim today is:

`Codex on Linux + pwsh` is now a formally promoted `full-authoritative` lane. `Codex on Linux without pwsh` remains explicitly `degraded-but-supported`.

Anything stronger is overclaim until the blockers above are closed.
