# Documentation Strategy Guide

Higher-level decisions about *what* to document *when*, and how to organize docs across projects and repositories.

## Contents

- [Project Maturity Stages](#project-maturity-stages)
- [Multi-Repo and Monorepo Strategy](#multi-repo-and-monorepo-strategy)
- [CHANGELOG Conventions](#changelog-conventions)

---

## Project Maturity Stages

Different project stages need different documentation. Writing the wrong docs at the wrong time wastes effort — either by over-documenting a prototype that'll pivot, or under-documenting a system that's about to onboard five new engineers.

### Prototype / Proof of Concept

**Team situation**: 1-2 people exploring an idea. Things change daily. The code *is* the documentation.

**Write**:
- README with a quick start (so someone else can run it)
- One ADR capturing why this approach is being explored over alternatives

**Skip everything else.** Conventions, conceptual guides, and detailed architecture docs will be wasted if the prototype pivots or dies. The ADR is the exception because it captures reasoning that's easy to lose and hard to reconstruct.

**Signal to move on**: The project gets approval to become a real thing, or a second person joins.

### First Real Version (v1)

**Team situation**: 2-5 people building toward production. Patterns are forming but still evolving. New people are joining who weren't there for the early decisions.

**Write**:
- README (signpost style)
- ADRs for every significant decision made so far (go back and capture the ones from the prototype phase too)
- Dev setup runbook (tested end-to-end)
- One conceptual guide covering the core architecture
- Initial conventions doc (even if it's short — it sets the expectation that conventions exist)

**Skip for now**: Domain-specific guides, detailed how-to guides, onboarding materials. The system is still small enough that a conceptual guide and some pairing covers it.

**Signal to move on**: The team grows past 5, or someone who wasn't part of the original build needs to work in the codebase independently.

### Growth / Active Development

**Team situation**: 5-15 people. Multiple workstreams. People can't hold the whole system in their heads anymore. Onboarding is becoming a bottleneck.

**Write everything the framework supports**:
- Full set of ADRs (backfill any gaps)
- Conceptual guides for each major domain
- Conventions docs (coding, git, review criteria)
- Onboarding guide
- How-to guides for recurring tasks
- Runbooks for operations (deployment, incidents, data tasks)

**Also consider**:
- Running the docs triage process (see [guide-triage.md](guide-triage.md)) if early docs have gone stale
- Setting up doc review as part of the PR process

**Signal to move on**: Development pace slows, the team stabilizes, or the project enters maintenance mode.

### Mature / Maintenance

**Team situation**: Stable team, infrequent changes. New features are rare; most work is bug fixes, dependency updates, and operational tasks.

**Priorities shift**:
- Runbooks become the highest-value docs (operational knowledge is what matters now)
- ADRs remain critical (future maintainers will ask "why was this built this way?")
- Conceptual guides should be reviewed and simplified — they may have accumulated complexity that no longer reflects the system
- How-to guides can be pruned if the tasks they describe are rare

**Watch for**: Docs that describe planned features or "future state" that never materialized. Clean these up — they confuse future readers.

### Handoff / End of Life

**Team situation**: The project is being transferred to another team, or is being retired.

**Write**:
- A "state of the project" document capturing: what works, what's known-broken, what's technical debt, what's actively dangerous
- Ensure ADRs are complete — the receiving team will need to understand *why* before they can safely change *what*
- Update the README to reflect the current state honestly (including if the project is deprecated)
- If retiring: add a clear deprecation notice to the README with alternatives or migration paths

---

## Multi-Repo and Monorepo Strategy

Where do docs live when you have multiple services or packages?

### Monorepo

All code in one repository. Docs should live close to the code they describe, with a shared top-level layer for cross-cutting concerns.

```
/
├── docs/                        # Cross-cutting documentation
│   ├── decisions/               # System-wide ADRs
│   ├── guides/                  # System-level conceptual guides
│   ├── conventions/             # Shared conventions
│   └── runbooks/                # Operational procedures
├── packages/
│   ├── service-a/
│   │   ├── docs/                # Service-specific docs
│   │   │   ├── decisions/       # Service-scoped ADRs
│   │   │   └── guides/          # Service-specific conceptual guides
│   │   ├── src/
│   │   └── README.md            # Service signpost
│   └── service-b/
│       ├── docs/
│       ├── src/
│       └── README.md
└── README.md                    # Repo-level signpost
```

**Rules for monorepos**:

- **System-wide decisions** (database choice, auth strategy, shared conventions) go in the top-level `/docs/decisions/`. If a decision affects more than one package, it's system-wide.
- **Service-specific decisions** (internal architecture of one service, library choices scoped to one package) go in that package's `docs/decisions/`.
- **The top-level README** is a signpost to the repo: what's in it, how packages relate, where to find docs. It should not try to describe every package.
- **Each package README** is a signpost for that package: what it does, how to run it, where its docs are.
- **Shared conventions** go in the top-level `/docs/conventions/`. Don't duplicate them in each package — breadcrumb to the shared copy.
- **Runbooks** generally live at the top level since operational procedures often span multiple services.

### Polyrepo (Multiple Repositories)

Each service or package in its own repo. The challenge is cross-cutting documentation that doesn't belong to any single repo.

**Option A: Dedicated docs repo**

```
org/
├── docs/                        # Standalone docs repo
│   ├── decisions/               # System-wide ADRs
│   ├── guides/                  # System-level conceptual guides
│   ├── conventions/             # Shared conventions
│   └── runbooks/                # Operational procedures
├── service-a/                   # Service repo
│   ├── docs/                    # Service-specific docs
│   ├── src/
│   └── README.md
└── service-b/                   # Service repo
    ├── docs/
    ├── src/
    └── README.md
```

This is the cleanest approach when you have 5+ repos and meaningful cross-cutting documentation. The docs repo becomes the "system documentation" and each service repo holds its own service-level docs.

**Option B: Designate a primary repo**

For smaller setups (2-4 repos), pick the most central repo to host system-wide docs. Add a `docs/system/` directory or similar to distinguish system docs from that repo's own docs. Less ceremony, but can get messy as the org grows.

**Option C: Wiki or external system**

Sometimes a wiki (Confluence, Notion, GitBook) is the right home for cross-cutting docs, especially if non-engineers need to contribute. The trade-off is that docs-as-code benefits (PR review, versioning, co-location) are lost.

**Rules for polyrepos**:

- Every service repo has its own README, ADRs, and service-specific guides
- System-wide decisions must live somewhere central — pick one of the options above and commit to it
- Each service README should link to where the system-level docs live
- Shared conventions should be in one place, with each repo breadcrumbing to them
- Avoid duplicating system-level content across repos — it will diverge

### Hybrid Guidance

Many real organizations are messy — some code in a monorepo, some in standalone repos, some in a wiki. The principles still apply:

1. **Every significant decision gets an ADR, and it lives near the code it affects.** System-wide decisions go in the central docs location. Service-scoped decisions go in the service.
2. **There is exactly one home for shared conventions.** Every other location breadcrumbs to it.
3. **Each repository's README is a signpost.** It links to both its own docs and the central system docs.
4. **Runbooks live where the operations team can find them.** If that's a wiki, fine. If that's a repo, fine. Just pick one.

---

## CHANGELOG Conventions

Both versions of this skill mention linking to changelogs, but a well-maintained CHANGELOG is itself a durable document worth getting right.

### What a CHANGELOG Is (and Isn't)

A CHANGELOG is a **curated, human-readable summary of notable changes** between releases. It is not:
- A git log dump (readers can run `git log` themselves)
- A complete list of every commit
- A marketing document

### Format

Follow [Keep a Changelog](https://keepachangelog.com/) conventions:

```markdown
# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- User preference for notification frequency (#234)

### Fixed
- Order total calculation rounding error (#228)

## [1.2.0] - 2026-03-15

### Added
- Batch export to CSV for order reports (#210)
- Rate limiting on public API endpoints (#215)

### Changed
- Upgraded authentication library to v3 (see ADR-0012)

### Deprecated
- Legacy XML export endpoint — will be removed in 2.0

### Removed
- Support for Node.js 18 (now requires 20+)

### Fixed
- Memory leak in long-running WebSocket connections (#220)

### Security
- Patched dependency vulnerability in image processing library (#222)

## [1.1.0] - 2026-02-01
...
```

### Categories

Use exactly these section headers (per Keep a Changelog):

| Category | When to Use |
|---|---|
| **Added** | New features or capabilities |
| **Changed** | Changes to existing functionality |
| **Deprecated** | Features that will be removed in a future release |
| **Removed** | Features that have been removed |
| **Fixed** | Bug fixes |
| **Security** | Vulnerability patches |

### Writing Good Entries

- **Lead with what changed for the user**, not what changed in the code. "Batch export to CSV for order reports" is better than "Added CsvExportService class."
- **Include issue or PR numbers** so readers can dig into details if needed.
- **Link to ADRs for significant changes.** If a change required an architectural decision, point to the record.
- **Group related changes.** If three commits together deliver one feature, write one CHANGELOG entry, not three.
- **Be honest about breaking changes.** Call them out clearly, with migration guidance or a link to it.

### Shelf Life of a CHANGELOG

A CHANGELOG is an interesting hybrid. Each *entry* has a short shelf life (it describes a moment in time), but the *document as a whole* has a long shelf life because it serves as a historical record. This makes it durable by design — entries are append-only, and old entries remain accurate because they describe what was true at that release.

The key is to avoid entries that reference volatile details:
```markdown
# Fragile entry
- Updated user table to add `preferences` column with JSON schema (see migration 047)

# Durable entry
- Added user notification preferences (#234)
```
