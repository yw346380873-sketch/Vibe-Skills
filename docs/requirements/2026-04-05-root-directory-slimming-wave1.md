# 2026-04-05 Root Directory Slimming Wave 1

## Goal

Execute the first root-directory slimming wave by reducing the number of top-level directories exposed at the repository root, while preserving runtime, installer, release, verification, and distribution behavior.

This wave targets only low-risk root surfaces that are good candidates for relocation or consolidation under existing semantic owners.

## Deliverable

A bounded root-directory cleanup that:

- audits the first-wave root candidates for live consumers
- moves or merges only the safest candidate directories
- updates affected path references and navigation where required
- leaves a smaller, cleaner repository root without weakening truth-surface ownership

## Constraints

- Work in the repository root (`<repo-root>`).
- Do not change `README.md` information architecture in this wave.
- Do not touch high-risk core truth surfaces such as `core/`, `config/`, `packages/`, `references/`, or `scripts/verify/**` unless a required path update is strictly incidental.
- Prefer existing owner families over creating new top-level families.
- Preserve compatibility where root paths are still part of release, packaging, or tool contracts.

## In Scope

- first-wave root candidates:
  - `hooks/`
  - `tools/`
  - `benchmarks/`
  - `commands/`
  - `dist/`
  - `distributions/`
- required path/reference updates caused by retained moves or merges
- governance docs and ledgers needed to explain the landed wave

## Out of Scope

- `README.md` portal rewrite
- high-risk root families such as `protocols/`, `rules/`, `schemas/`, `agents/`, `mcp/`, `apps/`, `adapters/`
- broad packaging or release redesign beyond the first-wave target roots

## Acceptance Criteria

1. Every first-wave candidate receives an explicit disposition: `move`, `merge`, or `keep`.
2. Only consumer-safe root changes are landed.
3. Any moved or merged directory has its callers and navigation updated in the same wave.
4. Verification proves that root slimming did not break targeted contracts.
5. The final root directory count is lower than the starting count.

## Product Acceptance Criteria

1. The repository root becomes easier to scan by reducing low-value top-level sprawl.
2. Ownership improves: helper or auxiliary content moves under stronger semantic parents.
3. Remaining high-risk root directories are explicitly deferred rather than vaguely ignored.

## Manual Spot Checks

- List the final root tree and confirm the removed top-level directories are gone.
- Open any retained moved directory README or manifest and confirm new paths still make semantic sense.
- Confirm root execution entrypoints such as `check.sh`, `install.sh`, and top-level distribution references still resolve correctly.

## Completion Language Policy

- Completion claims are limited to the first-wave root candidates and the verification run in this session.
- No claim may imply full root-architecture completion beyond this wave.

## Delivery Truth Contract

- Truth is wave-scoped: if a candidate keeps its root position due to live consumers, that is a valid governed outcome.
- Reduction is measured by safe root-width shrinkage, not by forcing every candidate to move.

## Non-Goals

- no cosmetic churn without directory-count payoff
- no speculative moves into worse owners
- no path deletions where compatibility remains under-proven

## Inferred Assumptions

- The best first wave is structural and low risk, not maximal.
- The user prefers a root that is shorter and more legible even if some historically messy surfaces remain for later waves.
