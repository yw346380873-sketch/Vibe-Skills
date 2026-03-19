[中文](./README.md)

# VibeSkills

> The core principle is standardization. Only with standardization can human intent be described clearly enough, AI work stay stable enough, and long-term maintenance and technical debt remain under control.

`VibeSkills` is the public-facing name. `VCO` is the governed runtime behind it.

This project is not about piling on more tools. It is about building a standardized way for humans and AI to work together: standardizing how humans describe needs, and standardizing how AI clarifies, plans, builds, verifies, and records the work so projects can be maintained with lower long-term technical debt.

<p align="center">
  <img src="./docs/assets/Gemini_Generated_Image_75f8n575f8n575f8.svg" alt="Original Gemini SVG provided by the author" width="100%" />
</p>

## Capability Snapshot

| What We Integrated | How It Works In The System | What It Means For Users |
| --- | --- | --- |
| `340` directly callable skills and capability modules | Organized by `dual-layer routing`, bringing skills, MCP, plugins, and workflow entry points into one runtime | You do not have to keep jumping between disconnected tools |
| `19` upstream projects and high-value practice sources absorbed into the system | Unified by the `governed runtime` so strong ideas from different projects work inside one flow | You get a governed system experience, not a loose bundle |
| `129` config-backed policies, contracts, and rules | Covering `verification and cleanup`, planning, traceability, boundaries, and rollback | Results are more stable, easier to maintain, and less likely to accumulate technical debt |

`VibeSkills` is not presenting a static directory of capabilities. It is presenting an AI system where capability integration, execution discipline, and governance density already live on the same surface.

This project integrates strengths from excellent upstream work such as `superpower`, `claude-scientific-skills`, `get-shit-done`, `aios-core`, `OpenSpec`, `ralph-claude-code`, and `SuperClaude_Framework`. The goal is not to make users memorize more commands. The goal is to let users focus on expressing needs to AI, while the later stages from requirement discovery and task planning to plan-driven implementation, verification, and maintenance can keep landing through a standardized workflow.

## Why It Feels Different Immediately

Most skill repositories answer one question: `what is available here?`

`VibeSkills` cares more about a different set of questions:

- what should be called now, instead of making you search the whole ecosystem yourself
- what should happen first, instead of letting the model sprint straight into execution
- which capabilities can be combined safely, and where boundaries need to stay explicit
- how results get verified, preserved, and kept out of long-term black-box decay

It is not about stacking more capability.
It is about integrating calling, governance, verification, and review into a system that can hold up under real use.

## The Real Problems It Tries To Solve

If you already use AI heavily, you have probably seen some version of these failures:

- too many skills, with no clear answer for which one fits the moment
- projects, plugins, and workflows that overlap and conflict with one another
- models that start executing before the task is actually clear
- work that ends without verification, evidence, or rollback surfaces
- a workflow that becomes more powerful over time, but also less understandable

`VibeSkills` does not pretend those problems disappear on their own.
Its value is that it takes them seriously and designs around them.

## How It Works

The easiest way to understand it is as three layers.

### 1. Smart routing

In the right situations, you should not have to remember which exact skill to call.

`VibeSkills` combines rule-based routing and AI-assisted routing so the right capability is more likely to be activated in the right context, without forcing you to memorize the ecosystem first.

### 2. Governed workflows

This is not only about calling tools.
It is also about how work gets done.

That is why the system tries to keep requirement clarification, confirmation, execution, verification, review, and traceability inside one working flow instead of letting the model sprint into a black box.

### 3. Integrated capabilities

This is not just a pile of skills.

It also includes plugins, project integrations, workflow design, AI norms, safety boundaries, maintenance lessons, and the mistakes I have already made and do not want to repeat.
`VCO` is the runtime layer that keeps those capabilities organized instead of leaving them scattered in unrelated places.

## Who It Is For

`VibeSkills` is mainly for:

- ordinary people who want AI to help more reliably
- heavy AI / Agent / automation users
- individuals or small teams that want more disciplined AI workflows
- anyone tired of a skill ecosystem that is rich in options but poor in usability

If you only want a single-purpose utility, this repo may be heavier than you need.
If you want AI to become steadier, easier to manage, and more useful over time, it is a much better fit.

## Start With Understanding

If you want the shortest path to understanding the system before you install it:

- [`docs/quick-start.en.md`](./docs/quick-start.en.md)
- [`docs/manifesto.en.md`](./docs/manifesto.en.md)

If you are ready to install after that, use the one-step AI-assisted entry:

- [`docs/install/one-click-install-release-copy.en.md`](./docs/install/one-click-install-release-copy.en.md)

If you are already a heavy user and want fuller install detail:

- [`docs/install/recommended-full-path.en.md`](./docs/install/recommended-full-path.en.md)
- [`docs/cold-start-install-paths.en.md`](./docs/cold-start-install-paths.en.md)

## In One Sentence

`VibeSkills` is not trying to sound more impressive.
It is trying to turn the most failure-prone part of real AI work into something more callable, more governable, more verifiable, and more maintainable over time.
