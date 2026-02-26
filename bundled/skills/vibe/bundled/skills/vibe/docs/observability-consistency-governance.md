# VCO Observability & Consistency Governance (Strict, Lean, Manual-Rollback)

## Design Goals

1. Strict: route and overlay behavior must be measurable and gateable.
2. Lean: avoid LLM-heavy monitoring by default; keep runtime context pressure minimal.
3. Adaptive: learn from real usage by environment/user profile, but never auto-apply risky changes.
4. Safe operations: rollback is notify-only, requires explicit user confirmation.

## Runtime Model

VCO keeps the existing routing pipeline unchanged and adds a post-route telemetry write:

- Config: `config/observability-policy.json`
- Writer: `scripts/router/resolve-pack-route.ps1` (`Write-ObservabilityRouteEvent`)
- Sink: `outputs/telemetry/route-events-YYYYMMDD.jsonl`

Telemetry is sampled by mode (`shadow/soft/strict`) and force-captures high-risk routes:

- `route_mode in {confirm_required, legacy_fallback}`
- any overlay requesting `confirm_required`

## Privacy and Context Budget

Default policy is low-context and privacy-safe:

1. Store `prompt_hash`, not raw prompt.
2. `prompt_excerpt` disabled by default (`prompt_excerpt_max_chars=0`).
3. Persist compact route fields only (grade/task/pack/skill/confidence/gap/route_mode + overlay flags).
4. Use profile IDs (`environment_profile_id`, `user_profile_id`) via hash, not raw identifiers.

## Failure Taxonomy (Deterministic)

`P0 hard_fail`:
- command-priority violation
- task boundary violation
- malformed router output

`P1 functional_fail`:
- selected candidate outside allowed contract
- expected `confirm_required` not raised
- out-of-scope overlay triggered as active

`P2 stability_fail`:
- gate threshold regression (`route_stability`, `top1_top2_gap`, `fallback_rate`, `misroute_rate`)

`P3 outcome_proxy_fail`:
- route appears valid, but downstream acceptance degrades significantly

## Learning Model (Offline, Manual Apply)

- Script: `scripts/learn/vibe-adaptive-train.ps1`
- Input: telemetry JSONL + current router thresholds
- Output: `outputs/learn/vibe-adaptive-suggestions.json` + markdown report
- Policy: bounded threshold deltas, manual review required

Suggested changes are advisory only. No automatic config mutation.

## Rollback Policy

Rollback policy is explicit and manual:

1. Publish script reports failure and emits rollback command.
2. Operator confirms with user.
3. Operator runs rollback command explicitly.

Automatic rollback execution is disabled by governance policy.

## Recommended Gate Chain

1. `scripts/verify/vibe-pack-routing-smoke.ps1`
2. `scripts/verify/vibe-config-parity-gate.ps1`
3. `scripts/verify/vibe-routing-stability-gate.ps1 -Strict`
4. `scripts/verify/vibe-observability-gate.ps1`

Only after all pass should rollout stage be advanced.
