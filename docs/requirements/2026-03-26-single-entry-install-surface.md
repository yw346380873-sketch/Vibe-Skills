# Requirement: Consolidate the Public Install Surface to One Entry

## Goal

Reduce user confusion by exposing one public install entry while keeping installation coverage complete across:

- supported hosts
- install vs update
- full vs minimal profiles

## User Intent

The public install surface should feel simple and low-friction.
Users should not have to choose between multiple install prompt pages before they even start.

## Required Outcome

The install documentation must:

1. expose one primary public install entry
2. retain the four base install/update prompt docs as the underlying execution surface
3. stop exposing additional install prompt pages as parallel public entrypoints
4. keep host-specific docs as supplemental references, not separate install lanes
5. describe extra host/provider/plugin/MCP configuration as optional enhancement guidance rather than hard-warning language when the base install is already usable

## Four Base Prompt Docs To Retain

- `docs/install/prompts/full-version-install.*`
- `docs/install/prompts/framework-only-install.*`
- `docs/install/prompts/full-version-update.*`
- `docs/install/prompts/framework-only-update.*`

## Public-Surface Rules

- `docs/install/one-click-install-release-copy.*` becomes the single public install entry
- `docs/install/README.*` should point normal users to that single entry
- top-level `README.md` should not expose multiple competing install prompt entries
- `full-featured-install-prompts.*` must no longer act as an additional public install prompt surface
- `framework-only-path.*` must no longer act as an additional public install prompt surface

## Configuration Guidance Rule

When local provider / plugin / MCP / host settings are optional follow-up work:

- describe them as recommended enhancements or optional next steps
- do not frame them as mandatory failure conditions when the core install already works
- still preserve truth about what remains host-managed

## Constraints

- do not remove the four retained base prompt docs
- do not reintroduce confusing install taxonomy into public docs
- do not add absolute local filesystem paths
- keep OpenClaw and OpenCode supplemental docs truthful but non-specialized
- do not touch unrelated untracked requirement/plan artifacts

## Acceptance Criteria

1. The public install surface has one clear primary entry.
2. The four retained prompt docs remain available.
3. `full-featured-install-prompts.*` no longer contains extra public install prompts.
4. `framework-only-path.*` no longer presents itself as a direct install entry.
5. `README.md` no longer presents multiple competing install entrypoints.
6. Bundled mirrors remain synchronized with source docs.
