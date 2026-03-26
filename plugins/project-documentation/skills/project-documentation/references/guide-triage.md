# Documentation Triage Guide

How to rescue an existing documentation set that's gone stale. This is the most common real-world scenario — you don't have a blank slate, you have 30-50 pages of docs in varying states of decay, and you need a plan.

## Contents

- [The Triage Mindset](#the-triage-mindset)
- [Phase 1: Inventory and Classify](#phase-1-inventory-and-classify)
- [Phase 2: Disposition](#phase-2-disposition)
- [Phase 3: Execute](#phase-3-execute)
- [Phase 4: Prevent Regression](#phase-4-prevent-regression)
- [Triage Decision Tree](#triage-decision-tree)
- [Common Triage Scenarios](#common-triage-scenarios)

---

## The Triage Mindset

The goal is not to "fix all the docs." The goal is to **maximize trust per hour spent**. Stale docs are worse than no docs — they actively mislead. Your first job is to stop the bleeding, then selectively rebuild.

Key principles:

- **Deleting is productive.** Removing a stale document is a positive contribution. It eliminates a trap for the next person who reads it.
- **Partial accuracy is dangerous.** A doc that's 80% correct is harder to deal with than one that's obviously wrong, because readers can't tell which 20% is the lie.
- **Triage is not rewriting.** Resist the urge to fix every document in-place. Classify first, then batch the work.

---

## Phase 1: Inventory and Classify

Walk through every existing document and tag it with two attributes:

### Shelf Life Category

What *type* of content does this document contain?

| Category | Signal | Example |
|---|---|---|
| **Decision** | Explains *why* something was chosen | "We picked Kafka because..." |
| **Conceptual** | Explains *how to think* about something | "The data pipeline works like..." |
| **Convention** | Establishes *what pattern to follow* | "Services use the repository pattern" |
| **Procedural** | Walks through *how to do* something | "To deploy, run these steps..." |
| **Reference** | Lists *what currently exists* | "The API has these endpoints..." |
| **Mixed** | Contains multiple categories blended together | Most stale docs fall here |

### Freshness Rating

How accurate is this document right now?

| Rating | Meaning | Action Bias |
|---|---|---|
| 🟢 **Fresh** | Accurate today | Keep, possibly reclassify |
| 🟡 **Stale** | Conceptually right, details wrong | Salvage the durable parts |
| 🔴 **Rotten** | Fundamentally misleading | Delete or quarantine |
| ⚫ **Unknown** | Can't tell without investigation | Flag for subject-matter expert |

### Quick Inventory Template

```markdown
| Document | Category | Freshness | Disposition |
|---|---|---|---|
| README.md | Mixed | 🟡 Stale | Rewrite as signpost |
| docs/architecture.md | Conceptual + Reference | 🟡 Stale | Split: keep conceptual, breadcrumb reference |
| docs/api-guide.md | Reference | 🔴 Rotten | Delete, point to OpenAPI |
| docs/setup.md | Procedural | 🟢 Fresh | Keep, minor cleanup |
| docs/database.md | Mixed | 🔴 Rotten | Extract ADR, delete the rest |
```

---

## Phase 2: Disposition

For each document, assign one of these dispositions:

### Keep As-Is
The document is fresh and already follows shelf-life principles. Maybe minor formatting cleanup.

### Rewrite
The *topic* is worth documenting, but the current document mixes durable and volatile content. Rewrite using the appropriate template, extracting what's durable and breadcrumbing the rest.

### Split
The document contains multiple shelf-life categories tangled together. Common pattern: an "architecture" doc that's half conceptual model (durable) and half endpoint inventory (volatile). Split into separate documents by category.

### Extract and Delete
The document is mostly rotten, but buried inside is a decision or convention worth preserving. Pull out the durable nugget (often as an ADR), then delete the rest.

### Delete
The document is either completely stale, duplicates something the code already expresses, or creates a parallel source of truth. Remove it. If you're nervous, move it to a `docs/_archive/` folder with a note about why it was retired.

### Redirect
The document covers something that's better served by generated docs, a dashboard, or a tool. Replace the content with a one-line breadcrumb pointing to the authoritative source.

---

## Phase 3: Execute

### Recommended Order

Work in this sequence to maximize impact per hour:

1. **Delete rotten docs first.** Immediate trust improvement. Five minutes of deleting can prevent hours of wasted debugging by teammates following bad instructions.

2. **Redirect reference docs to generated sources.** Replace endpoint lists, config catalogs, and schema dumps with breadcrumbs. Quick wins.

3. **Extract ADRs from stale docs.** Mine existing docs for decision rationale — it's often buried in prose that's otherwise stale. This captures institutional knowledge before it's lost.

4. **Rewrite the README.** High-traffic document, high visibility. Convert it from a sprawling overview into a signpost.

5. **Write missing conceptual guides.** These have the longest shelf life and the highest ratio of value to maintenance cost.

6. **Rewrite procedural docs (setup, deployment).** Test them end-to-end as you rewrite.

7. **Add conventions docs last.** These need team buy-in and are better written after you've established the patterns through the previous steps.

### Batch by Type

Group similar dispositions together. Rewriting 5 reference docs into breadcrumbs is faster when done in a batch than interleaved with conceptual guide work. Context switching between documentation styles is expensive.

---

## Phase 4: Prevent Regression

Triage is wasted effort if the docs rot again in six months. Build in structural defenses:

### Structural Defenses

- **Organize by shelf life.** The `/docs/` directory structure in the main skill guide groups docs by how often they change. This makes it visible when someone puts volatile content in a durable location.

- **README as signpost only.** A README that's just links and a quick start has almost nothing that can go stale.

- **Breadcrumb by default.** Establish the team norm that new docs breadcrumb to code for anything volatile. Review docs PRs with this lens.

### Process Defenses

- **Docs review in PRs.** When code changes invalidate a breadcrumb path, the PR should update the breadcrumb. This is cheap because breadcrumbs are one-liners.

- **Quarterly freshness check.** A 30-minute scan of `/docs/` once a quarter catches drift before it compounds. Look for documents that narrate volatile details.

- **New ADR trigger.** When a significant decision is made in Slack, a meeting, or a PR comment, someone should write it up. Decisions are the highest-value docs and the easiest to lose.

---

## Triage Decision Tree

For each existing document, walk through this:

```
Is this document actively misleading someone today?
  YES → Delete or quarantine immediately
  NO ↓

Does this document narrate volatile details (endpoints, schemas, config)?
  YES → Can those details be found in code/config/generated docs?
    YES → Replace content with a breadcrumb → done
    NO → Keep for now, flag for future auto-generation
  NO ↓

Does this document explain WHY a decision was made?
  YES → Is the decision still in effect?
    YES → Reformat as an ADR if it isn't already
    NO → Mark as superseded, write new ADR for current decision
  NO ↓

Does this document explain HOW TO THINK about something?
  YES → Is the conceptual model still accurate?
    YES → Keep, clean up, breadcrumb any volatile details
    NO → Rewrite with current mental model
  NO ↓

Does this document walk through HOW TO DO something?
  YES → Test the steps right now. Do they work?
    YES → Keep, breadcrumb any embedded volatile details
    NO → Rewrite and test, or delete if the process has changed entirely
  NO ↓

What's left is probably a document that doesn't fit cleanly.
→ Check if anyone has read it in the last 6 months
→ If not, archive it. If yes, figure out what need it serves and rewrite to serve that need properly.
```

---

## Common Triage Scenarios

### "The 40-page Architecture Doc"

Almost always a mix of durable conceptual content and rotten implementation details. Split it:
- Extract the 2-3 pages of "how to think about the system" into a conceptual guide
- Extract any decision rationale into ADRs
- Delete the rest (endpoint lists, class diagrams, deployment topology specifics)
- Add breadcrumbs to code for anything that was accurate but volatile

### "The Wiki Nobody Maintains"

Wikis accumulate content without curation. Triage aggressively:
- Export the page list
- Classify each page using the inventory template
- Expect to delete 50-70% of pages
- Migrate survivors into the repo's `/docs/` structure

### "The README That's a Novel"

A README that tries to be all the docs at once. Replace with the signpost pattern:
- Keep: title, one-line description, quick start
- Move: architecture content → `docs/guides/`
- Move: setup details → `docs/runbooks/dev-setup.md`
- Delete: API reference, config tables, dependency lists
- Add: documentation links table pointing to where everything landed

### "The Confluence Graveyard"

Pages created for projects or initiatives that have ended or evolved:
- Search for pages not edited in 12+ months
- Check if the project/initiative is still active
- For dead projects: archive the entire space
- For active projects with stale docs: apply the standard triage process
- Migrate anything worth keeping into the code repo

### "I Inherited This and Don't Know What's Accurate"

The most common triage scenario — and the one most guides ignore. You're looking at docs for a system you didn't build, and you can't tell what's still true.

**Adjust the process:**

1. **Start with what you _can_ verify.** Runbooks and setup guides are testable — follow the steps and see if they work. This gives you quick wins (fix or delete broken procedures) and teaches you about the system simultaneously.

2. **Use the code as your ground truth.** For any doc that makes claims about the codebase, spot-check against reality. Does the file path exist? Does the directory structure match? If a doc says "we use the repository pattern," is there evidence of it in the code?

3. **Mark what you can't verify.** For documents about design decisions, historical context, or business rationale — you often can't verify these against code. Don't delete them just because you can't confirm them. Instead, tag them as "unverified — needs SME review" and move on. If the original authors are reachable, ask them to spend 15 minutes scanning their old docs.

4. **Prioritize by traffic, not by age.** A stale doc that nobody reads is harmless. A stale doc that every new hire follows is actively dangerous. If you can identify which docs people actually use (git blame on the docs, asking the team, checking wiki analytics), triage those first.

5. **Don't try to understand everything before triaging.** You don't need to fully grok the system to classify a doc as "this is an inventory of volatile details that should be a breadcrumb." Many triage decisions are structural, not domain-specific.

**What to do first when you arrive:**
- Run the dev setup guide. Does it work? If not, fix it — this is your first PR and it teaches you the system.
- Read the README. Is it a signpost or a novel? If the latter, it's a good early rewrite candidate.
- Ask the team: "Which doc have you found most misleading?" Fix that one. Trust is built by removing traps, not by adding content.
