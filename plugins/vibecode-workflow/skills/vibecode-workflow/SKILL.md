---
name: vibecode-workflow
description: >
  Inject and maintain vibecode-workflow project guidelines in a project's CLAUDE.md file.
  Use this skill whenever the user mentions vibecode-workflow setup, initialization, or validation.
  Trigger on phrases like "set up vibecode-workflow", "initialize project guidelines",
  "validate my CLAUDE.md", "check vibecode-workflow config", "add workflow guidelines",
  or any reference to ensuring CLAUDE.md contains the standard development process
  (brainstorming, worktrees, TDD, code review, superpowers, episodic-memory).
  Also trigger when the user creates a new project and mentions wanting the standard
  development workflow, or when they suspect their CLAUDE.md is missing guidelines.
---

# vibecode-workflow

Ensures a project's `CLAUDE.md` includes the vibecode-workflow development guidelines from `references/SETUP.md`.

## How it works

The skill has two modes: **initialize** and **validate**. Both are idempotent.

### Sentinel markers

The injected content is wrapped in markers so it can be detected and updated deterministically:

```
<!-- vibecode-workflow:start -->
(content from SETUP.md, possibly customized)
<!-- vibecode-workflow:end -->
```

These markers are the primary detection mechanism. Agent review is used as a secondary validation step to confirm completeness.

## Initialize mode

Use when the user wants to add vibecode-workflow guidelines to a project for the first time, or when no markers are detected in CLAUDE.md.

### Steps

1. Read `references/SETUP.md` from this skill's directory.
2. Check if `CLAUDE.md` exists at the project root.
   - If it doesn't exist, create it.
3. Search `CLAUDE.md` for `<!-- vibecode-workflow:start -->`.
   - If found, switch to **validate mode** instead.
4. Ask the user if they want to customize the guidelines before injection. Examples of customizations:
   - Adding or removing skills from the "Required Skills" list
   - Changing the worktree directory
   - Adjusting documentation requirements
   - Adding project-specific rules to the "Additional Rules" section
5. If the user provides customizations, apply them to the SETUP.md content before injection.
6. Append the following to `CLAUDE.md`, preserving any existing content:

```
<!-- vibecode-workflow:start -->
{SETUP.md content, with any customizations applied}
<!-- vibecode-workflow:end -->
```

7. Confirm to the user what was added and where.

## Validate mode

Use when the user wants to verify their CLAUDE.md still contains the vibecode-workflow guidelines, or when initialize mode detects existing markers.

### Steps

1. Read `references/SETUP.md` from this skill's directory.
2. Read `CLAUDE.md` from the project root.
3. Locate the `<!-- vibecode-workflow:start -->` and `<!-- vibecode-workflow:end -->` markers.
   - If markers are missing, inform the user and offer to run **initialize mode**.
4. Extract the content between the markers.
5. Review the extracted content against `references/SETUP.md` and check:
   - All required sections are present (Required Skills, Skill Usage Rules, Development Process, Debugging, Additional Rules, Documentation Requirements).
   - No critical steps have been removed (TDD, code review, worktree setup).
   - The development process order is intact (Brainstorm → Worktree → Plan → Execute → TDD → Code Review → Finish).
6. Report findings:
   - **All good**: Confirm guidelines are intact.
   - **Drift detected**: List what's missing or changed, and offer to update the block by replacing everything between the markers with a fresh copy of SETUP.md (re-applying any customizations the user specifies).

## Customization

The user may provide customizations at initialization or during validation/update. When customizations are requested:

- Apply them to the SETUP.md content before writing to CLAUDE.md.
- Document what was customized in the output so the user has a record.
- During validation, if the content differs from the reference SETUP.md, ask the user whether the differences are intentional customizations or unintended drift before overwriting.

## Important details

- Never remove or overwrite existing CLAUDE.md content outside the markers. The markers define the skill's territory — everything else belongs to the user or other tools.
- If CLAUDE.md has content before the markers, preserve it exactly.
- If CLAUDE.md has content after the markers, preserve it exactly.
- When updating, replace only the content between (and including) the markers.
