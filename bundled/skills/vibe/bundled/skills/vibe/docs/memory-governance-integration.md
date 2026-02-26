# Memory Governance Integration (VCO)

## Purpose

Integrate a strict role-boundary model for memory systems in VCO without introducing route conflicts or a second control plane.

This integration is designed to:
- Keep `/vibe` as the only routing entrypoint
- Keep pack selection unchanged
- Add post-route memory guidance to reduce overlap and context pollution

## Governance Contract

VCO memory role boundaries are:

1. `state_store`: session state only
2. `Serena`: explicit project decisions only
3. `ruflo`: short-term session vector cache only
4. `Cognee`: long-term graph memory + relationship retrieval only
5. `episodic-memory`: disabled in VCO governance path

## Non-Conflict Design

1. **No routing override**: memory governance does not change `selected.pack_id` or `selected.skill`.
2. **Post-route advice only**: router emits `memory_governance_advice` metadata.
3. **Mode-ready without lock-in**: supports `off|shadow|soft|strict`, but default is `shadow`.
4. **Fallback-safe**: if governance config is missing, VCO keeps core routing path unchanged.

## Config

Primary policy file:
- `config/memory-governance.json`

Bundled mirror:
- `bundled/skills/vibe/config/memory-governance.json`

Key fields:
- `enabled`, `mode`
- `task_allow`, `grade_allow`
- `role_boundaries`
- `defaults_by_task`
- `fallback_behavior`

## Router Integration

Router file:
- `scripts/router/resolve-pack-route.ps1`

Output addition:
- `memory_governance_advice`

Advice payload includes:
- scope applicability and enforcement level
- task-level memory defaults (`primary_memory`, `project_decision_memory`, `short_term_memory`, `long_term_memory`)
- disabled systems list
- governance contract snapshot

## Verification

Run dedicated memory governance gate:

```powershell
pwsh -File .\scripts\verify\vibe-memory-governance-gate.ps1
```

Run config parity gate:

```powershell
pwsh -File .\scripts\verify\vibe-config-parity-gate.ps1
```

## Failure Semantics

- Missing governance config: bypass overlay advice, keep routing unchanged
- Policy set to `off`: emit disabled advice object
- Hook/runtime errors: continue core VCO routing path
- Disabled memory request (episodic-memory): advise role-mapped alternative (`Cognee` or `Serena`)
