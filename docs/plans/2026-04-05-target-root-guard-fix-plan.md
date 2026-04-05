# 2026-04-05 Target Root Guard Fix Plan

## Goal

Restore the codex target-root mismatch guard by fixing the shared adapter ownership detector first, then proving the shell entrypoints pick up the repaired behavior.

## Requirement Doc

- [`../requirements/2026-04-05-target-root-guard-fix.md`](../requirements/2026-04-05-target-root-guard-fix.md)

## Internal Grade

M single-lane governed execution.

The scope is a narrow bug fix with targeted tests and no need for delegation.

## Frozen Scope

### Update

- `packages/installer-core/src/vgo_installer/adapter_registry.py`
- `tests/unit/test_installer_adapter_registry_target_roots.py`

### Verify

- `tests/runtime_neutral/test_check_shell_target_root_guard.py`
- `tests/runtime_neutral/test_bootstrap_shell_target_root_guard.py`

## Architecture Rule

Fix the root cause at the shared ownership detection layer.

- do not patch shell scripts if they already contain the correct host-intent behavior
- preserve existing opencode compatibility signatures
- add the smallest new signature surface needed for cursor detection

## Execution Steps

### Step 1: Confirm Root Cause

- reproduce `--target-root-owner` for `.cursor` and `.opencode`
- confirm `.cursor` currently returns empty while `.opencode` returns `opencode`

### Step 2: Add Failing Unit Coverage

- extend target-root registry tests with a cursor signature case

### Step 3: Implement Minimal Repair

- update adapter target-root signatures so cursor-like roots map to `cursor`

### Step 4: Verify Shell Consumers

- run targeted unit test
- run the two runtime-neutral shell guard tests

## Verification

- `python3 -m pytest tests/unit/test_installer_adapter_registry_target_roots.py -q`
- `python3 -m pytest tests/runtime_neutral/test_check_shell_target_root_guard.py tests/runtime_neutral/test_bootstrap_shell_target_root_guard.py -q`

## Rollback

- revert the single patch if the new signature creates unintended host matching

## Phase Cleanup

- leave only intentional governed docs plus the code/test fix in the worktree
- emit phase and cleanup receipts after targeted verification
