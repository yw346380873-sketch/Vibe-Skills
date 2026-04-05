# 2026-04-05 Root Directory Slimming Wave 1 Outcome

## Landed Change

- `tools/` -> `move`
  - converged into `scripts/build/` and `scripts/release/`
  - active callers, tests, and live readme surfaces were updated in the same wave
  - result: one root directory family removed without weakening runtime or release ownership

## Deferred Or Retained Candidates

- `hooks/` -> `keep`
  - still exact-path bound to install, check, adapter closure, and distribution manifests
- `commands/` -> `keep`
  - still part of adapter/runtime compatibility contracts
- `benchmarks/` -> `keep`
  - low payoff and still referenced by scenario fixtures and workflow acceptance tests
- `dist/` -> `keep`
  - release-facing truth surface with active config and integration-test consumers
- `distributions/` -> `defer`
  - currently small, but still tied to release-facing documentation semantics and not worth a risky merge in this wave

## Result

- Root-directory count decreased by 1 in this wave.
- Ownership improved by moving build/release materializers under the existing `scripts/` operator family.
- The remaining first-wave candidates now have explicit dispositions for future waves instead of staying ambiguous.
