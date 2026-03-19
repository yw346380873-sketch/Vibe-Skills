# Public README Gemini Art Direction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rework the public README hero around the author-provided Gemini-generated SVG so the homepage feels editorial and art-directed while preserving key capability information.

**Architecture:** Keep the README GitHub-safe. Use the author SVG as a style source, generate a compact editorial panel and a matching mark from its visual language, then rebuild the first screen as a two-column hero with lighter information density.

**Tech Stack:** Markdown, GitHub-safe HTML tables, local SVG assets, governed docs indexes, git verification commands

---

### Task 1: Freeze the Gemini art-direction pass

**Files:**
- Create: `docs/requirements/2026-03-19-public-readme-gemini-art-direction.md`
- Create: `docs/plans/2026-03-19-public-readme-gemini-art-direction-design.md`
- Create: `docs/plans/2026-03-19-public-readme-gemini-art-direction-plan.md`
- Modify: `docs/requirements/README.md`
- Modify: `docs/plans/README.md`

**Step 1: Write the frozen requirement**

Capture the user-provided source artwork, the balanced editorial direction, and the GitHub rendering constraints.

**Step 2: Write the design document**

Record why the image should be cropped and reorganized rather than inserted whole.

**Step 3: Register the pass**

Add the new requirement and plan to the current-entry indexes.

### Task 2: Create the source-derived assets

**Files:**
- Create: `docs/assets/vibeskills-gemini-editorial-panel.svg`
- Create: `docs/assets/vibeskills-gemini-mark.svg`

**Step 1: Create the editorial panel**

Generate a portrait-oriented panel that preserves the source artwork's palette, tonal stacking, and editorial feeling.

**Step 2: Create the mark**

Generate a compact square mark from the same style family for the README top identifier.

**Step 3: Verify assets exist**

Run: `ls docs/assets/vibeskills-gemini-editorial-panel.svg docs/assets/vibeskills-gemini-mark.svg`
Expected: both SVG files listed

### Task 3: Rebuild the README hero layout

**Files:**
- Modify: `README.md`
- Modify: `README.en.md`

**Step 1: Replace the current centered poster block**

Swap the old full-width hero + separate logo stack for a two-column editorial hero.

**Step 2: Use the new Gemini mark**

Place the new cropped mark at the top of the left column as the visual identifier.

**Step 3: Use the new editorial panel**

Place the cropped panel in the right column with a restrained caption.

**Step 4: Lighten the metric treatment**

Turn the three large metric cards into a tighter editorial number strip.

**Step 5: Verify the first-screen order**

Run: `sed -n '1,120p' README.md && echo '---' && sed -n '1,120p' README.en.md`
Expected: language link, two-column hero, new mark, number strip, and right-column art panel appear in order

### Task 4: Verify scope and prep for push

**Files:**
- None intentionally beyond receipts

**Step 1: Verify diff scope**

Run: `git diff --stat -- README.md README.en.md docs/assets/vibeskills-gemini-editorial-panel.svg docs/assets/vibeskills-gemini-mark.svg docs/requirements/2026-03-19-public-readme-gemini-art-direction.md docs/plans/2026-03-19-public-readme-gemini-art-direction-design.md docs/plans/2026-03-19-public-readme-gemini-art-direction-plan.md docs/requirements/README.md docs/plans/README.md`
Expected: only README, assets, and governance trace files appear

**Step 2: Verify worktree state**

Run: `git status --short --branch`
Expected: only intended Gemini art-direction changes remain
