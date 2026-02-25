# Prompt Overlay Integration (prompts.chat x VCO)

## Purpose

Integrate `prompts.chat` as a prompt asset layer in VCO without introducing a second orchestrator.

This overlay is designed to:
- Keep `/vibe` as the only routing entrypoint
- Provide prompt-template discovery/refinement hints post-route
- Reduce prompt-vs-doc routing ambiguity through semantic confirm gates

## Non-Redundancy Boundaries

1. **Single routing authority**: VCO pack router remains the control plane.
2. **Post-route advisory/guard only**: overlay emits `prompt_overlay_advice`; it does not replace pack selection.
3. **No second workflow surface**: no `/prompts:*` lifecycle is introduced into VCO.
4. **Asset-plane responsibility**: prompts.chat is used for prompt assets (template/rewrite/publish), not general API docs retrieval.

## Config

Primary policy file:
- `config/prompt-overlay.json`

Bundled mirror:
- `bundled/skills/vibe/config/prompt-overlay.json`

Key fields:
- `enabled`, `mode` (`off|shadow|soft|strict`)
- `task_allow` (default: `planning`, `research`)
- `grade_allow` (default: `M`, `L`, `XL`)
- `confirm_scope` (where ambiguity can escalate to `confirm_required`)
- `prompt_signal_keywords`
- `doc_surface_keywords`
- `intent_facets` (`template_seek`, `prompt_refine`, `prompt_publish`)

## Runtime Behavior

Router file:
- `scripts/router/resolve-pack-route.ps1`

Output additions:
- `prompt_overlay_advice`
- `prompt_overlay_route_override`

Semantics:
- In `shadow`: advisory only.
- In `soft`: if prompt/doc collision is detected within `confirm_scope`, route is upgraded to `confirm_required`.
- In `strict`: same collision triggers `confirm_required`; prompt-heavy in-scope requests become `required` in advice metadata.
- Outside collision conditions, routing remains unchanged.

## Conflict Control

To avoid prompt/doc cross-talk:
- `prompt-lookup` gains stronger prompt-intent positive keywords.
- `prompt-lookup` gets doc-surface negative keywords.
- `openai-docs` / `documentation-lookup` / `openai-knowledge` receive prompt-intent negative keywords.

This ensures:
- prompt template/refine requests prefer `prompt-lookup`
- official API/doc requests stay in doc-focused skills
- ambiguous requests are explicitly confirmed instead of silently misrouted

## Verification

Run dedicated overlay gate:

```powershell
pwsh -File .\scripts\verify\vibe-prompt-overlay-gate.ps1
```

Run parity gate (main vs bundled config):

```powershell
pwsh -File .\scripts\verify\vibe-config-parity-gate.ps1
```

## Failure Semantics

Overlay failures are non-fatal by default:
- missing config -> bypass overlay advice
- policy disabled -> no effect on route decision
- no prompt signals -> no overlay-driven escalation

Only prompt/doc ambiguity in configured scope can enforce `confirm_required`.
