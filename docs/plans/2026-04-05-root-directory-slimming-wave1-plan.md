# 2026-04-05 Root Directory Slimming Wave 1 Plan

## Goal

Reduce root-directory sprawl in one bounded, reviewable wave by relocating or consolidating only the safest top-level directories.

## Requirement Doc

- [`../requirements/2026-04-05-root-directory-slimming-wave1.md`](../requirements/2026-04-05-root-directory-slimming-wave1.md)

## Internal Grade

XL wave-sequential execution with bounded parallel audits.

The change surface is path-sensitive, but the candidate directories are independent enough to audit in parallel before root-governed integration.

## Ownership Lanes

### Lane A: Auxiliary Operator Roots

Write scope:

- `hooks/`
- `tools/`
- `commands/`
- related path updates under `docs/`, `scripts/`, and `config/`

### Lane B: Quality / Sample Roots

Write scope:

- `benchmarks/`
- related references under `docs/`, `tests/`, or `config/`

### Lane C: Distribution Roots

Write scope:

- `dist/`
- `distributions/`
- related release, packaging, and manifest references

### Lane D: Root-Governed Integration

Write scope:

- requirement / plan / status artifacts
- final directory moves
- cross-lane conflict resolution

## Execution Steps

### Stage 0: Freeze and Audit

- freeze requirement and plan
- audit each root candidate for exact-path and semantic consumers
- classify candidates into `move`, `merge`, or `keep`

### Stage 1: Lowest-Risk Moves

- land only candidates whose consumers are narrow and easy to retarget
- prefer moving auxiliary helper directories under `scripts/` or `tests/`

### Stage 2: Distribution Decision

- merge `dist/` and `distributions/` only if release and packaging callers can be safely updated in one pass
- otherwise keep both and record blocker evidence

### Stage 3: Root Verification and Cleanup

- verify moved roots no longer exist at top level
- verify targeted tests, path scans, and diff hygiene
- run node audit / cleanup simulation

## Candidate Heuristics

- `hooks/` likely belongs under `scripts/`
- `tools/` likely belongs under `scripts/`
- `commands/` may belong under `docs/commands/` or `scripts/commands/` depending on consumers
- `benchmarks/` likely belongs under `tests/benchmarks/` if not used as a release-facing surface
- `dist/` and `distributions/` should be merged only if they are semantically redundant rather than merely adjacent

## Verification Commands

- `git diff --check`
- repo-wide `rg` scans for moved root paths
- targeted tests or scripts for any touched distribution or installer callers
- final root listing to prove directory-count reduction

## Rollback Rules

- if a candidate has broad live consumers, downgrade it to `keep` for this wave
- if a move requires touching high-risk release or runtime truth surfaces, stop and defer that candidate
- integrate one candidate cluster at a time to keep revert scope narrow

## Phase Cleanup Expectations

1. remove temporary audit files if created
2. verify the worktree contains only intended path updates
3. run node audit / cleanup simulation
4. record retained blockers for the next root wave
