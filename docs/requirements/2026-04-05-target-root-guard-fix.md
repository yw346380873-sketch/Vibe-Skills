# 2026-04-05 Target Root Guard Fix

## Goal

Repair the codex shell target-root guard failures by fixing the underlying target-root ownership detection so Cursor-like and OpenCode-like roots are rejected before deeper shell execution proceeds.

## Deliverable

A minimal patch that:

- identifies temporary `.cursor` paths as cursor-owned target roots
- preserves existing `.opencode` compatibility handling
- causes the existing shell guard logic to reject mismatched codex target roots with the expected guidance text
- proves the fix with targeted unit and runtime-neutral tests

## Constraints

- Work in `/home/lqf/table/table9/Vibe-Skills-main`.
- Do not bundle `bundled/**` deduplication or unrelated cleanup into this fix.
- Preserve existing host-intent guard wording unless a test requires otherwise.
- Prefer fixing the shared root-cause layer instead of patching each shell script separately.

## In Scope

- `packages/installer-core/src/vgo_installer/adapter_registry.py`
- targeted unit tests for target-root ownership detection
- targeted runtime-neutral tests covering `check.sh` and `scripts/bootstrap/one-shot-setup.sh`

## Out of Scope

- bundled skill deduplication
- runtime-surface contract fallback cleanup
- installer or check behavior unrelated to target-root host intent

## Acceptance Criteria

1. `resolve_target_root_owner()` recognizes temporary `.cursor` paths as `cursor`.
2. Existing `.opencode` target-root recognition remains intact.
3. `check.sh --host codex --target-root <tmp>/.cursor` exits non-zero before generic missing-file checks and emits Cursor-specific guidance.
4. `scripts/bootstrap/one-shot-setup.sh --host codex --target-root <tmp>/.cursor` exits non-zero before installation proceeds and emits Cursor-specific guidance.
5. Targeted tests for the repaired behavior pass.

## Product Acceptance Criteria

1. The fix lands as a narrow, reviewable repair for priority item 1.
2. The patch reduces maintenance risk for later slimming work by restoring trust in host-intent guards.

## Manual Spot Checks

- Run `python3 scripts/common/adapter_registry_query.py --repo-root . --target-root-owner <tmp>/.cursor` and confirm it prints `cursor`.
- Run the targeted shell guard tests and confirm their stderr still contains `Cursor home` and `OpenCode root`.

## Completion Language Policy

- This slice may claim only that the target-root guard bug was fixed and the targeted verification passed.
- It must not claim broader repository health or unrelated guard correctness.

## Delivery Truth Contract

- Truth for this slice is limited to adapter target-root detection and the shell guard paths that consume it.

## Non-Goals

- No repo slimming in this slice.
- No packaging-contract refactor in this slice.

## Inferred Assumptions

- The root-cause layer is the correct place to repair the failure because both shell entrypoints consume the same ownership query.
