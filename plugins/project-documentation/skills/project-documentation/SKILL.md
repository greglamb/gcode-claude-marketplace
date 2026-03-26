---
name: project-documentation
description: "Write software documentation that resists decay. Use this skill whenever the user wants to create, improve, or organize technical documentation — including READMEs, architecture docs, ADRs, developer guides, onboarding materials, conventions, runbooks, how-to guides, or any project docs. Trigger on phrases like 'document this repo', 'write a README', 'create an ADR', 'my docs are a mess', 'set up a docs structure', 'help me write a developer guide', or 'make our docs stop going stale'. Also trigger when asked to triage or clean up existing documentation, decide what to document at different project stages, organize docs across multiple repos, write CLAUDE.md or AI context files, or integrate documentation into PR workflows. Covers five domains (infrastructure, data, API, engineering, product) with ready-to-use templates and worked examples."
---

# Durable Documentation

Write project documentation that stays useful by matching your writing approach to each topic's shelf life.

## The Problem with Traditional Docs

Most project documentation tries to describe the current state of the system. But current state changes constantly — every merged PR can invalidate what's written. The result: docs that are stale within weeks and that nobody trusts.

## The Fix: Write for Shelf Life

Every piece of documentation content has a **shelf life** — how long it'll remain accurate before the underlying reality changes. The trick is to match your approach to the shelf life of what you're writing about.

### Long Shelf Life — Write It All Down

Content that rarely changes deserves full, detailed documentation. This is the highest-value writing you can do because it stays useful for months or years.

**What qualifies:**

- **Decision records**: The reasoning behind architectural choices doesn't change even when the implementation evolves. "We picked PostgreSQL because of X, Y, Z" stays true regardless of schema changes.
- **Conceptual models**: How to think about the system — the metaphors, the boundaries, the flow. "Data enters through ingestion, gets enriched, then lands in storage" remains valid even as specific services come and go.
- **Team conventions**: Agreed-upon patterns and practices. "We use feature branches with conventional commits" changes only when the team decides to change it.
- **Onboarding paths**: How to get oriented in the project. "Start by understanding the domain layer, then look at how services compose" survives individual code changes.

### Medium Shelf Life — Write the Concept, Link the Details

Content that changes occasionally. The *shape* is stable but the *specifics* drift. Write the conceptual framing, then link to the authoritative source for current details.

**What qualifies:**

- Component responsibilities and boundaries (the role is stable; the interface evolves)
- Integration patterns (the approach is stable; endpoints and payloads change)
- Data flow overviews (the pipeline shape is stable; stages get added/removed)

**The pattern:**

```markdown
The authentication layer uses a pluggable strategy approach, making it
straightforward to add new identity providers. See `src/auth/strategies/`
for the currently supported providers and `IAuthStrategy` for the
interface contract.
```

### Short Shelf Life — Breadcrumb, Don't Narrate

Content that changes with every PR. Don't write prose about it — leave a trail of breadcrumbs pointing to where the truth lives.

**What qualifies:**

- Current list of endpoints, services, config options, feature flags
- Schema definitions and type signatures
- Specific version numbers, resource counts, IP addresses
- Anything where the code or config is the single source of truth

**The pattern:**

```markdown
# Instead of listing every config option:
Configuration follows the schema in `config.schema.json`. Copy `.env.example`
to `.env` and adjust for your environment.

# Instead of inventorying API endpoints:
API documentation is generated from source. Run `npm run docs` or visit
`/api-docs` on a running instance.
```

## Decision Flowchart

Before writing anything, run this test:

```
Does this explain WHY something exists?         → Write it fully (decision record)
Does this explain HOW TO THINK about something? → Write it fully (conceptual guide)
Does this establish WHAT PATTERN TO FOLLOW?     → Write it fully (conventions)
Does this describe WHAT CURRENTLY EXISTS?       → Breadcrumb to code/config
Does this walk through HOW TO DO A TASK?        → Write the steps, breadcrumb the specifics
```

## Breadcrumb Phrases

Use these to point without narrating:

| Don't write this | Write this instead |
|---|---|
| "The available configuration options are..." | "See `config.schema.json` for available options" |
| "The system currently has these services..." | "See `src/services/` for the current service inventory" |
| "The API supports these endpoints..." | "See the generated API docs at `/api-docs`" |
| "The database tables include..." | "See migration files in `src/migrations/` for the current schema" |

## Anti-Patterns

These signal documentation that will decay rapidly:

- **Inventories**: "We currently have 12 microservices: X, Y, Z..."
- **Parallel truth**: Maintaining docs AND code as dual sources of truth for the same information
- **Implementation narration**: Prose descriptions of what code does (let code comments handle this)
- **Copy-pasted type signatures**: Reproducing interfaces or schemas in markdown

## The Operator's Guide Test

Good documentation reads like an **operator's guide** — it tells you enough to work with the system competently. Bad documentation reads like a **service manual** — it tries to catalog every internal detail exhaustively.

**Operator's guide** (write this):
- How to get started and get oriented
- What each component is *for* (its role, not its internals)
- Key constraints, guardrails, and gotchas
- "For full specifications, see the generated reference docs"

**Service manual** (avoid this):
- Complete inventory of every internal part
- Exhaustive parameter-by-parameter specification
- Full wiring diagrams showing every dependency
- Troubleshooting matrix for every possible system state

When reviewing a draft, ask: *"Could an operator use this to work effectively in the system, without it trying to replace reading the code?"* If yes, it's the right level. If it's so detailed that it competes with the source code for truth, it's a service manual and it'll rot.

## Documentation Architecture

Organize docs by shelf life and purpose:

```
/docs/
├── decisions/           # Long shelf life — why we chose what we chose
│   ├── 0001-database-choice.md
│   └── 0002-auth-strategy.md
├── guides/              # Long shelf life — how to think about the system
│   ├── architecture.md
│   ├── data-model.md
│   └── product-overview.md
├── conventions/         # Long shelf life — team agreements
│   ├── coding-standards.md
│   └── git-workflow.md
├── runbooks/            # Long shelf life — operational procedures
│   ├── dev-setup.md
│   ├── deployment.md
│   └── incident-response.md
└── how-to/              # Medium shelf life — task walkthroughs
    ├── add-new-service.md
    └── run-migrations.md
```

Note the absence of a `reference/` directory — prefer generated docs or direct code links for reference material.

## README Philosophy

A README is a **signpost**, not a textbook. Its job is four things:

1. **Identity**: What is this? (one sentence)
2. **Audience**: Who is it for?
3. **Proof of life**: Can I get it running? (copy-paste quick start)
4. **Wayfinding**: Where do I go to learn more?

Everything else belongs in `/docs/`.

### README Section Order

1. Title + one-line description
2. Quick Start (copy-paste to validate)
3. What It Does (outcomes, not internals)
4. Example (one minimal usage)
5. Documentation links (to the real docs)
6. Contributing / Security / License

### What Doesn't Belong in a README

- Full API reference → generate from code
- Architecture deep-dives → `docs/guides/`
- Tutorials → `docs/how-to/`
- Exhaustive troubleshooting → `docs/runbooks/troubleshooting.md`
- Configuration reference → link to schema or example file

## Workflow

### 0. Consider the Bigger Picture (If Needed)

For strategic documentation decisions, consult:

- [Documentation Strategy](references/guide-strategy.md) — What to write at each project maturity stage, how to organize docs across monorepos and polyrepos, CHANGELOG conventions
- [Documentation Triage](references/guide-triage.md) — How to rescue an existing set of stale docs: inventory, classify, triage, and prevent regression

These are relevant when starting a new project, inheriting a codebase, or cleaning up neglected documentation. For routine doc writing, skip to step 1.

### 1. Assess Content Shelf Life

Before writing, classify every topic using the decision flowchart above.

### 2. Pick the Right Domain Guide

For domain-specific documentation, consult the appropriate reference:

- [Infrastructure docs](references/guide-infrastructure.md) — Cloud, IaC, networking, observability
- [Data docs](references/guide-data.md) — Databases, schemas, pipelines, ETL
- [API docs](references/guide-api.md) — REST/GraphQL, auth flows, integration guides
- [Engineering docs](references/guide-engineering.md) — Codebase, architecture, dev environment
- [Product docs](references/guide-product.md) — Features, user journeys, analytics, releases

Each guide specifies what to write fully, what to write-and-link, and what to breadcrumb for that domain.

### 3. Select a Template

Pick from the template library based on what you're writing:

- [Long shelf life templates](references/templates-long-shelf.md) — Decision records, conceptual guides, conventions, onboarding
- [Medium shelf life + supporting templates](references/templates-medium-shelf.md) — Architecture overviews, how-to guides, troubleshooting, CONTRIBUTING, SECURITY
- README templates by project type:
  - [Applications and libraries](references/templates-readme-apps.md) — Node.js, npm packages, React, Web APIs, databases
  - [Infrastructure and operations](references/templates-readme-ops.md) — Containers, Terraform, CI/CD, Lambda, ECS, messaging

For completed examples showing what finished docs look like (not just skeletons), see [references/examples/](references/examples/).

### 4. Apply the Writing Standards

Follow the [writing standards](references/writing-standards.md) for tone, formatting, shelf-life-aware style rules, diagram durability guidance, and a before/after rewrite gallery.

### 5. Set Up Ongoing Workflows

For keeping docs alive in day-to-day development:

- [Documentation Workflows](references/guide-workflows.md) — Docs-in-PRs checklist, composing across domains, and documenting AI-assisted codebases (CLAUDE.md, .cursorrules, etc.)

### 6. Run the Freshness Audit

When documenting an existing project, identify gaps:

- Are there decision records for major architectural choices?
- Do conceptual guides exist for each major domain?
- Are team conventions written down?
- Do runbooks cover critical operations (setup, deploy, incidents)?
- Is any documentation narrating volatile details instead of breadcrumbing?

Fill gaps using the domain guides and templates. Prioritize long-shelf-life content first — it delivers the most lasting value.

---

## Further Reading

This skill draws on established ideas from the documentation community. If you want to go deeper:

- **[Diátaxis](https://diataxis.fr/)** — Grand Unified Theory of documentation, organizing content into tutorials, how-to guides, explanation, and reference. The shelf life framework is compatible with Diátaxis and adds the durability dimension.
- **[Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)** — Michael Nygard's original blog post that started the ADR movement.
- **[Architecture Decision Records](https://adr.github.io/)** — Community hub for ADR tooling, templates, and conventions.
- **[Docs as Code](https://www.writethedocs.org/guide/docs-as-code/)** — Write the Docs guide to treating documentation with the same rigor as source code (version control, review, testing).
- **[Google Developer Documentation Style Guide](https://developers.google.com/style)** — Comprehensive style reference for technical writing.
- **[The Documentation System](https://documentation.divio.com/)** — Divio's practical take on the four documentation quadrants.
