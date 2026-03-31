# Claude Code Platform Proof Review 2026-03-31

## Purpose

This status page records the current platform-proof decision for the Claude Code host lane after the managed-closure upgrade.

It is a bounded promotion snapshot for Linux.
It is still a no-overclaim status page.

## Current Decision

- `claude-code` host status may remain `supported-with-constraints` at the host-contract level.
- `claude-code/linux` is now `supported-with-constraints` for the bounded managed-closure lane because the Linux proof bundle is frozen and replay truth is synchronized.
- `claude-code/windows` remains `not-yet-proven`.
- `claude-code/macos` remains `not-yet-proven`.

## Why Linux Can Move But Others Cannot

The repository now has a bounded Claude managed-closure lane:

- install/check can write and verify a managed `vibeskills` node
- install/check can write and verify a managed `PreToolUse` hook entry
- the managed `write-guard.js` hook is materially exercised on a real Linux host
- a real local `claude` CLI command surface succeeds against the managed Linux target root

That is enough for a bounded Linux `supported-with-constraints` claim.
It is not enough for Windows or macOS platform promotion.
It is also not enough for any `official-runtime` or whole-host guarantee claim.

## Evidence State

| Lane | Current Status | Promotion State | Reason |
| --- | --- | --- | --- |
| `claude-code/linux` | `supported-with-constraints` | promoted for bounded managed closure only | frozen Linux install/check/coherence/CLI smoke bundle exists and replay truth is synchronized |
| `claude-code/windows` | `not-yet-proven` | blocked | local VM host now exists, but Windows guest proof is still blocked by real TCG guest-boot instability before install/check/smoke capture |
| `claude-code/macos` | `not-yet-proven` | blocked | no fresh-machine macOS replay or host-native smoke proof |

## Required Future Evidence

Further platform promotion review may reopen only after all of the following are frozen:

1. fresh-machine install proof for the target platform
2. fresh-machine check proof for the target platform
3. real Claude CLI smoke proof for the target platform
4. replay fixture synchronization
5. bundle manifest + status decision synchronization

Canonical machine-readable ceiling:

- `references/proof-bundles/claude-code-managed-closure-candidate/manifest.json`
- `tests/replay/promotion/claude-code-managed-closure.json`

## Additional Windows Truth From This Batch

The repository now has a repo-owned local Windows VM harness on Ubuntu, but that is still below platform-proof level.

Concrete evidence from the current host:

- the Microsoft Windows 11 evaluation ISO can be downloaded and validated
- the current session is itself virtualized on `kvm`, but `/dev/kvm` is not passed through, so this environment cannot be used as the next KVM-backed proof host
- the VM can boot far enough to hit the optical `Press any key to boot from CD or DVD...` gate
- the `cpu=max` TCG path reaches WinPE and then crashes with stop code `SYSTEM_THREAD_EXCEPTION_NOT_HANDLED (0x7E)`
- the `cpu=qemu64` TCG path reaches the UEFI shell, where Windows EFI payloads on the ISO are visible but at least one Microsoft EFI app (`memtest.efi`) returns `Command Error Status: Unsupported`
- the new BIOS / SeaBIOS lane does not clear the blocker:
  `pc + legacy-ide + bios` falls into SeaBIOS `iPXE`, while `q35 + ahci + bios` still reaches the same Windows stop code `SYSTEM_THREAD_EXCEPTION_NOT_HANDLED (0x7E)`
- the repository now has an explicit `--require-kvm` guardrail and a `check-kvm-host-readiness.sh` probe so the next operator can refuse accidental `tcg` fallback on the future host
- Microsoft also maintains an official developer-VM lane, but that download surface was marked temporarily unavailable on October 23, 2024, so it is a valid next fallback only if Microsoft reopens it

That is enough to justify continued Windows proof work.
It is not enough to justify any promotion wording above `not-yet-proven`.

## Guardrail

Any future wording that claims:

- Linux above `supported-with-constraints`
- Windows above `not-yet-proven`
- macOS above `not-yet-proven`

without their corresponding frozen artifacts is overclaim and should fail review.
