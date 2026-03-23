# Prompt-Based Install (Recommended Default)

This is the default recommended installation path.

## 🚀 Quick Navigation

**If you want to use prompts directly, please choose**:

- 📦 [Full Version Install Prompt](./prompts/full-version-install.en.md) - Ready to use with complete features
- 🔧 [Framework Only Install Prompt](./prompts/framework-only-install.en.md) - Install governance framework only
- 🔄 [Full Version Update Prompt](./prompts/full-version-update.en.md) - Update installed full version
- 🔄 [Framework Only Update Prompt](./prompts/framework-only-update.en.md) - Update installed framework version

**Reference Documentation**:
- 📋 [Installation Rules](./installation-rules.en.md) - 13 core installation rules
- ⚙️ [Configuration Guide](./configuration-guide.en.md) - VCO configuration details

---

Public versions are consolidated into two options:

- `Full Version + Customizable Governance`
- `Framework Only + Customizable Governance`

Current script layer still uses lane implementation:

- `Full Version + Customizable Governance` corresponds to `full`
- `Framework Only + Customizable Governance` corresponds to `framework-only`

`workflow` is retained as a compatibility/transition lane but is no longer the main recommended version for regular users.

Currently only two target hosts are supported:

- `codex`
- `claude-code`

## Quick Conclusion

If you don't want to study lane/profile/host details first, understand it this way:

- Want ready-to-use with ability to add your own workflow/skill governance later: choose `Full Version + Customizable Governance`
- Want only the governance framework and add workflow/skill governance yourself later: choose `Framework Only + Customizable Governance`

Publicly, we only present these two versions without requiring regular users to understand `workflow`/`full`/`framework-only` first.

## Quick Selection

| Public Version | Actual Profile | What You Get | What You Don't Get Directly | Who It's For |
| --- | --- | --- | --- | --- |
| `Full Version + Customizable Governance` | `full` | `vibe` runtime, canonical router, complete governance framework, default workflow core, extended bundled capabilities | Auto-completed hooks, auto-completed provider/MCP/online readiness | Users who want ready-to-use experience and plan to add custom workflows later |
| `Framework Only + Customizable Governance` | `framework-only` | `vibe` runtime, canonical router, install/check/doctor, routing and overlay/policy governance skeleton | Default workflow core, extensive bundled workflow/domain skills | Users who only want the governance foundation and plan to gradually add workflow/skills themselves |

## What You Need to Do

1. Choose host: `codex` or `claude-code`
2. Choose public version: `Full Version + Customizable Governance` or `Framework Only + Customizable Governance`
3. Copy the corresponding prompt below to AI and let AI execute the installation

After installation, if you want to add your own workflow/skills, continue with:

- [`custom-workflow-onboarding.en.md`](./custom-workflow-onboarding.en.md)
- [`custom-skill-governance-rules.en.md`](./custom-skill-governance-rules.en.md)

## Version Description

### 1. Full Version + Customizable Governance

You will get:

- `vibe` runtime and canonical router
- Complete governance framework
- Default workflow core
- Extended bundled capabilities
- Entry point to continue integrating your own custom workflow/custom skill governance

Suitable for:

- Want ready-to-use experience
- Plan to continue managing your own workflows later
- Don't want to add too many basic workflow skills yourself first

### 2. Framework Only + Customizable Governance

You will get:

- `vibe` runtime and canonical router
- install/check/doctor and other governance surfaces
- Routing, execution levels, overlay/policy governance skeleton
- Foundation to continue integrating custom workflow/custom governance

You will NOT get directly:

- Ready-to-use experience of default workflow core
- Extensive bundled workflow/domain skills

Suitable for:

- Only want to keep the governance framework
- Want to decide which workflow/skills to integrate later
- Can accept continuing to add custom workflow manifest and governance rules yourself

## Prompts to Copy to AI

For the detailed prompts, please refer to the individual prompt files:

- [Full Version Install Prompt](./prompts/full-version-install.en.md)
- [Framework Only Install Prompt](./prompts/framework-only-install.en.md)
- [Full Version Update Prompt](./prompts/full-version-update.en.md)
- [Framework Only Update Prompt](./prompts/framework-only-update.en.md)

## What You'll See After Installation

Regardless of which version you choose, after installation you should receive a concise result summary including at least:

- Target host
- Public version
- Actual mapped profile
- Commands actually executed
- Completed parts
- Parts still requiring manual handling

Recommended understanding:

- "Installation complete" ≠ "hooks installed"
- "Basic online provider configured" ≠ "governance AI online layer ready"
- "Core framework installed" ≠ "default workflow core complete"
- "Skill directory exists" ≠ "custom workflow managed by router"

## What It Won't Pretend to Complete for You

The following may still be user-side or host-side actions:

- Local host configuration
- MCP registration and authorization (optional enhancements as needed)
- Hook compatibility waiting (currently author-side compatibility boundary, not your installation failure)
- Local `url`/`apikey`/`model` configuration
- Manual updates to Claude Code's real `settings.json`
- Custom workflow manifest declaration and governance rule completion

## How to Continue Adding Custom Skills/Governance After Installation

Follow the governed integration path:

- First complete current public version installation
- Then see [`custom-workflow-onboarding.en.md`](./custom-workflow-onboarding.en.md)
- Then see [`custom-skill-governance-rules.en.md`](./custom-skill-governance-rules.en.md)

Recommended understanding:

- Full version: Get default workflow core and extended capabilities first, then integrate your own governance
- Framework version: Get foundation first, then gradually integrate your own workflow/skill governance by manifest

If your goal is "integrate your own workflows right after installation", recommended order:

1. First install `Full Version + Customizable Governance`
2. Then establish manifest per [`custom-workflow-onboarding.en.md`](./custom-workflow-onboarding.en.md)
3. Then complete governance boundaries per [`custom-skill-governance-rules.en.md`](./custom-skill-governance-rules.en.md)
4. Finally run `check`/doctor again for verification

## How Old-Version Users Should Upgrade

If you already installed an older version, you usually don't need to uninstall first.
For most users, simply re-run this prompt-based install flow.

In practice, that means asking AI to run one more install pass with this prompt.
If that install completes normally, you usually don't need any extra manual commands.

Only use the more detailed upgrade commands when:

- AI cannot run the install for you
- You need to debug a failed upgrade manually
- You explicitly want to upgrade to a specific release or tag

Then see:

- [`recommended-full-path.en.md`](./recommended-full-path.en.md)

## Second Main Install Path

If you do not want AI to run installation, or the environment is offline or has no admin rights, use:

- [`manual-copy-install.en.md`](./manual-copy-install.en.md)

## Advanced References

If you need the more detailed host boundaries, see:

- [`recommended-full-path.en.md`](./recommended-full-path.en.md)
- [`full-path.en.md`](./full-path.en.md)
- [`framework-only-path.en.md`](./framework-only-path.en.md)
- [`../cold-start-install-paths.en.md`](../cold-start-install-paths.en.md)
