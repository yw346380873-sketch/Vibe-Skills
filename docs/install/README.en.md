# Installation and Custom Integration Index

This directory contains public installation and custom integration documentation.

## 🚀 Quick Navigation

### New User Installation

**Recommended: Use streamlined prompts** (optimized and deduplicated):

- 📦 **[Full Version Install](./prompts/full-version-install.en.md)** - Ready to use with complete features
- 🔧 **[Framework Only Install](./prompts/framework-only-install.en.md)** - Install governance framework only

### Existing User Updates

- 🔄 **[Full Version Update](./prompts/full-version-update.en.md)** - Update installed full version
- 🔄 **[Framework Only Update](./prompts/framework-only-update.en.md)** - Update installed framework version

### Reference Documentation

- 📋 **[Installation Rules](./installation-rules.en.md)** - 13 core installation rules
- ⚙️ **[Configuration Guide](./configuration-guide.en.md)** - VCO configuration details

---

## 📖 Version Description

Current public versions are consolidated into two options:

- `Full Version + Customizable Governance`
- `Framework Only + Customizable Governance`

Current script implementation still retains three lanes:

- `framework-only`
- `workflow`
- `full`

Among them:

- `full` corresponds to the public "Full Version + Customizable Governance"
- `framework-only` corresponds to the public "Framework Only + Customizable Governance"
- `workflow` is retained as a compatibility/transition lane, no longer the main choice for regular users

## Start Here

- [`one-click-install-release-copy.en.md`](./one-click-install-release-copy.en.md): Default recommended entry point, contains prompt installation templates for both public versions
- [`full-path.en.md`](./full-path.en.md): Full version corresponding to underlying `full` lane reference
- [`framework-only-path.en.md`](./framework-only-path.en.md): Framework version corresponding to underlying `framework-only` lane reference
- [`workflow-path.en.md`](./workflow-path.en.md): Compatibility/transition lane reference, no longer the main entry for regular users

## Custom Extensions

- [`custom-workflow-onboarding.en.md`](./custom-workflow-onboarding.en.md): How to integrate new workflows into governance and routing
- [`custom-skill-governance-rules.en.md`](./custom-skill-governance-rules.en.md): Governance rules and boundaries for custom skills/workflows

## Host Boundaries (Must Confirm First)

Currently supported hosts only include:

- `codex`
- `claude-code`

Among them:

- `codex`: governed official path
- `claude-code`: preview guidance (not full closure)

Unsupported hosts cannot pretend installation success or online readiness completion.

## Compatibility Notes

During the phase when old parameters and old lanes still exist:

- `minimal` is equivalent to `workflow`
- `full` is still equivalent to `full`

For public communication, prioritize using "public version names" without requiring regular users to understand lanes first:

- `Full Version + Customizable Governance`
- `Framework Only + Customizable Governance`

## Recommended Reading Order

If you are a regular user, recommended reading order:

1. [`one-click-install-release-copy.en.md`](./one-click-install-release-copy.en.md)
2. [`custom-workflow-onboarding.en.md`](./custom-workflow-onboarding.en.md)
3. [`custom-skill-governance-rules.en.md`](./custom-skill-governance-rules.en.md)

If you are an advanced user wanting to see underlying profile/lane correspondence, then see:

1. [`full-path.en.md`](./full-path.en.md)
2. [`framework-only-path.en.md`](./framework-only-path.en.md)
3. [`workflow-path.en.md`](./workflow-path.en.md)
