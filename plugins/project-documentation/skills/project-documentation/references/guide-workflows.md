# Documentation Workflows

Practical patterns for keeping documentation alive in day-to-day development, composing docs across domains, and documenting AI-assisted codebases.

## Contents

- [Documentation in Pull Requests](#documentation-in-pull-requests)
- [Composing Across Domains](#composing-across-domains)
- [Documenting AI-Assisted Codebases](#documenting-ai-assisted-codebases)

---

## Documentation in Pull Requests

The best time to update docs is when you're changing the code they describe. Baking this into the PR process makes it routine rather than a separate chore.

### What to Check in Every PR

Not every PR needs doc changes, but every PR deserves a quick mental scan:

**Did I move, rename, or delete a file or directory that a doc breadcrumbs to?**

This is the most common way docs break. A breadcrumb like "See `src/auth/strategies/`" takes 2 seconds to update if you catch it during the PR, and 2 hours to debug if a new hire hits it next month.

Search for the old path across docs:
```bash
grep -r "old/path" docs/ README.md
```

**Did I make or change an architectural decision?**

If you chose a new library, changed an integration approach, or established a new pattern, capture it as an ADR while the reasoning is fresh. This takes 15 minutes during the PR versus an hour next month when you've forgotten the nuances.

**Did I establish a new convention or deviate from an existing one?**

If you introduced a new pattern, update the conventions doc. If you broke from convention, leave a code comment (and consider whether the convention itself should change).

**Did I change how something is configured or deployed?**

Update the relevant runbook or how-to guide. Breadcrumbs to config files are usually stable, but if you changed the config structure itself (new required env var, renamed setting), update `.env.example` and any docs that reference the old name.

### PR Review Checklist for Docs

Add to your team's PR template:

```markdown
### Documentation

- [ ] Breadcrumb paths still valid (no broken `See src/...` references)
- [ ] ADR written if a significant decision was made
- [ ] Conventions doc updated if a new pattern was introduced
- [ ] Runbook updated if operational procedures changed
- [ ] `.env.example` updated if configuration changed
```

### What NOT to Do in PRs

Don't update docs that narrate volatile details — that's the anti-pattern this whole skill exists to prevent. If a doc says "We currently have 3 auth strategies" and you add a 4th, the fix isn't to update the number to 4. The fix is to rewrite the line as a breadcrumb: "See `src/auth/strategies/` for the current set."

Every time you find a doc narrating volatile content during a PR, it's an opportunity to convert it to a breadcrumb. This is how docs gradually get more durable over time without a dedicated cleanup sprint.

### Keeping Breadcrumbs Valid Automatically

For teams that want automated protection:

```bash
# Simple: grep docs for paths and check they exist
# Add to CI pipeline
find docs/ README.md -name "*.md" -exec grep -ohP 'src/[a-zA-Z0-9/_.-]+' {} \; | sort -u | while read path; do
  [ ! -e "$path" ] && echo "BROKEN BREADCRUMB: $path"
done
```

This catches the most common breakage — references to paths that no longer exist. It won't catch subtler issues (renamed functions, changed interfaces), but those should be breadcrumbing to directories, not specific files.

---

## Composing Across Domains

Real projects span multiple domains. An order processing service has API, data, engineering, and product concerns. The domain guides in this skill cover each domain individually, but here's how they fit together.

### Pick a Primary Domain

Every document has a primary domain — the one that determines its structure and focus. A document about "how the order API validates requests" is primarily an API doc, even though it touches engineering patterns and data validation.

Use the primary domain's guide to structure the document. Reference other domains inline when they're relevant, but don't try to cover everything.

### Cross-Domain Decision Records

Some decisions span multiple domains. "We chose event sourcing for orders" is simultaneously a data decision, an engineering decision, and an API decision (because it affects how state is queried).

Write one ADR, filed in the most relevant domain's decisions folder. Add a brief "See Also" reference from the other domains:

```markdown
# In docs/decisions/0005-event-sourcing-orders.md
(the full ADR lives here)

# In the data architecture guide:
Order history uses event sourcing (see ADR-0005).

# In the API integration guide:
Order queries use CQRS projections due to the event-sourced storage model (see ADR-0005).
```

One ADR, multiple breadcrumbs — never duplicate the reasoning.

### Cross-Domain Conceptual Guides

When a service touches many domains, you'll often want a single "How to Think About [Service]" guide rather than fragments scattered across domain-specific docs. Structure it around the service's purpose, and pull in domain-specific guidance as subsections:

```markdown
# Order Service: How to Think About It

## What It Does
(product-level framing)

## Data Model
(pull from data domain guidance)
See data architecture guide for system-wide data flow.

## API Surface
(pull from API domain guidance)
See API integration guide for authentication and pagination patterns.

## Infrastructure
(pull from infrastructure domain guidance)
See infrastructure guide for deployment topology.
```

### Avoiding Duplication

The rule: **every fact lives in one place**. Other documents breadcrumb to it.

Common duplication traps:
- Writing about the auth flow in both the API guide and the engineering guide → Pick one home, breadcrumb from the other
- Describing the deployment process in both the infrastructure guide and the engineering setup runbook → Deployment lives in infrastructure; the engineering runbook links to it
- Explaining the data model in both the product guide and the data guide → The conceptual model lives in the data guide; the product guide describes user-facing behavior and links to the data guide for internals

---

## Documenting AI-Assisted Codebases

AI coding assistants (Claude Code, GitHub Copilot, Cursor, etc.) are increasingly part of how teams build software. This creates a new category of documentation that doesn't fit neatly into the traditional hierarchy — but the shelf life framework still applies.

### What's New: Context Files

Most AI coding tools consume context files that shape how the AI behaves in a project. These files are themselves documentation — they describe conventions, patterns, and project-specific rules. Common examples:

- `CLAUDE.md` — Project context for Claude Code
- `.cursorrules` — Project rules for Cursor
- `.github/copilot-instructions.md` — Context for GitHub Copilot
- Custom slash commands, prompt templates, memory files

### Shelf Life of Context Files

Context files follow the same durability spectrum:

**Long shelf life content in context files** (document fully):
- Architectural patterns and conventions the AI should follow
- Code style rules and naming conventions
- Design principles and constraints
- "Always do X, never do Y" rules

**Medium shelf life content** (document + breadcrumb):
- Project structure overview (the shape is stable, specific files change)
- Key abstractions and how they relate
- Testing approach and expectations

**Short shelf life content** (breadcrumb or omit):
- Lists of current files or modules (the AI can read the filesystem)
- Specific implementation details (the AI can read the code)
- Dependency versions (the AI can read the manifest)

### Writing Effective Context Files

Context files are read by an AI, not a human, but the shelf life principle still applies — if you put volatile details in a context file, they'll go stale and the AI will generate code based on outdated information.

```markdown
# CLAUDE.md — Good Example

## Architecture
This project uses a layered architecture. Dependencies flow inward:
api → application → domain ← infrastructure

## Conventions
- Feature folders in src/application/features/
- Every feature has a command/query, handler, and tests
- Use the repository pattern for data access
- Error types extend AppError (see src/domain/errors/)

## Testing
- Unit tests co-located with source files (*.test.ts)
- Integration tests in tests/integration/
- Target 80% line coverage

## Key Constraints
- All database access goes through repositories, never direct queries
- Domain layer has zero external dependencies
- API responses follow the envelope pattern in src/api/responses/
```

```markdown
# CLAUDE.md — Bad Example (volatile content that'll go stale)

## Current Modules
- OrderService (src/services/orders.ts) - handles order CRUD
- UserService (src/services/users.ts) - handles user management
- PaymentService (src/services/payments.ts) - handles payments via Stripe

## Database Tables
- orders (id, customer_id, status, total, created_at)
- users (id, email, name, role, created_at)
- payments (id, order_id, amount, stripe_id, status)
```

### Relationship to Project Documentation

Context files and project documentation serve different audiences (AI vs. humans) but share the same source of truth. Ideally:

- **Conventions doc** is the authoritative source for team agreements → the context file references or summarizes it
- **ADRs** capture decisions → the context file distills the implications into rules the AI should follow
- **Conceptual guides** explain the mental model → the context file summarizes the key abstractions

Don't maintain parallel versions of the same information in both the context file and the docs. If your conventions doc says "use feature folders," the context file should either reference it or state the same rule — not elaborate a different version that can drift.

### Documenting AI-Specific Workflows

If your team uses AI tools as part of the development workflow, consider documenting:

**In your conventions doc** (long shelf life):
- When and how AI tools should be used (code generation, review, refactoring)
- What gets human review before merging (all AI-generated code? only certain areas?)
- How to handle AI-suggested patterns that conflict with project conventions

**In your onboarding guide** (long shelf life):
- Which AI tools the team uses and how they're configured
- Where context files live and how to update them
- Common AI-assisted workflows (generating tests, scaffolding features)

**As an ADR** (long shelf life):
- The decision to adopt a specific AI tool and the reasoning behind it
- Boundaries on what AI tools can and can't access (sensitive data, production systems)

### Keeping Context Files Durable

Apply the same PR checklist to context files that you apply to docs. When conventions change, update both the conventions doc and the context file. When architecture evolves, update the conceptual guide and the context file summary.

The good news: context files that follow shelf life principles are naturally more effective, because the AI gets stable, accurate guidance rather than a snapshot of implementation details that's already stale.
