# Templates: Long Shelf Life

Templates for the most durable documentation — content that captures *reasoning* and *mental frameworks* and survives implementation churn.

## Contents

- [Decision Record (ADR)](#decision-record-adr)
- [Conceptual Guide](#conceptual-guide)
- [Conventions Document](#conventions-document)
- [Onboarding Guide](#onboarding-guide)

For completed examples of these templates in use, see the [examples directory](examples/).

---

## Decision Record (ADR)

The single most durable document you can write. Capture it whenever a decision would take more than 30 minutes to reconstruct, touches multiple components, or constrains what you can do in the future.

```markdown
# ADR-NNNN: [Concise Title]

**Status**: [Proposed | Accepted | Deprecated | Superseded by ADR-XXXX]

**Decided**: YYYY-MM-DD

**Participants**: [Names or roles involved]

## Situation

[What circumstances led to this decision? What constraints or pressures apply?]

## Resolution

[What was decided? State it plainly in one or two sentences.]

## Reasoning

[Why this option over the others?]

### Alternatives Evaluated

**Option A: [Name]**
- Upside: [Benefit]
- Downside: [Drawback]

**Option B: [Name]** ← chosen
- Upside: [Benefit]
- Upside: [Benefit]
- Downside: [Trade-off we accepted]

**Option C: [Name]**
- Upside: [Benefit]
- Downside: [Disqualifying issue]

### Deciding Factors

[What tipped the scale toward the chosen option?]

## Implications

**Benefits**:
- [What we gain]

**Trade-offs**:
- [What we accept as a cost]

**Side effects**:
- [Neutral consequences worth knowing about]

## See Also

- [Related ADR or external resource]
- [Relevant code: `src/path/`]
```

**Good ADR titles**: ADR-0001: PostgreSQL for transactional storage, ADR-0002: Event-driven order processing, ADR-0003: Trunk-based branching model

---

## Conceptual Guide

Builds the reader's intuition about a system or component. A good conceptual guide helps someone reason about unfamiliar situations — it's not a map of the code, it's a way of thinking.

```markdown
# [System/Component]: How to Think About It

## The Big Idea

[One paragraph capturing the core abstraction. If you had to explain this
system using a metaphor, what would it be?]

## Key Ideas

### [Idea 1]

[What is it? Why does it exist? What mental model should the reader have?]

### [Idea 2]

[Continue for each foundational concept...]

## The Typical Flow

[Walk through how things move through the system. Keep it conceptual —
describe the journey, not the code.]

```
[ASCII or Mermaid diagram showing relationships at a conceptual level,
not class diagrams or code structure]
```

## Scope

### This System Handles
- [Responsibility 1]
- [Responsibility 2]

### This System Does NOT Handle
- [Out of scope 1 — point to what does handle it]
- [Out of scope 2 — point to what does handle it]

## Common Misconceptions

### "Doesn't X handle Y?"

[Clear up a frequent source of confusion]

### "Why not just do Z?"

[Explain the constraint or trade-off that makes Z impractical]

## Navigating the Code

For current implementation details:
- [Idea 1]: See `src/path/`
- [Idea 2]: See `src/other/path/`
- [Configuration]: See `config.schema.json`
```

---

## Conventions Document

Captures team agreements that guide daily coding decisions. "When you encounter X, do Y."

```markdown
# [Project/Team] Conventions

These conventions represent how we've agreed to work. Follow them by default —
if you need to deviate, leave a comment explaining why and mention it in your PR.

## Project Layout

```
src/
├── core/           # [What lives here and why]
├── services/       # [What lives here and why]
├── shared/         # [What lives here and why]
└── types/          # [What lives here and why]
```

## Naming Rules

| Kind | Pattern | Example |
|------|---------|---------|
| Files | [convention] | `order-service.ts` |
| Classes | [convention] | `OrderService` |
| Interfaces | [convention] | `IOrderRepository` |
| Constants | [convention] | `MAX_RETRY_ATTEMPTS` |

## Code Patterns

### Adding a New Service

1. [Instruction]
2. [Instruction]
3. See `src/services/orders/` as a working reference

### Adding an API Endpoint

1. [Instruction]
2. [Instruction]

### Handling Errors

[Describe the agreed-upon approach]

```typescript
// Illustrative example of the expected pattern
```

## Git Practices

### Branch Names

```
feature/TICKET-123-brief-description
fix/TICKET-456-brief-description
```

### Commit Messages

```
feat: implement order validation
fix: handle null response from payment gateway
docs: add data model conceptual guide
```

## Code Review Expectations

A PR is ready to merge when:
- [ ] [Expectation 1]
- [ ] [Expectation 2]
- [ ] [Expectation 3]

## Breaking from Convention

If you need to do something differently:
1. Add a code comment explaining the rationale
2. Call it out in the PR description
3. Consider whether the convention itself needs updating
```

---

## Onboarding Guide

Helps a new developer go from zero to oriented. Focuses on *navigation* — where to look and what to understand first.

```markdown
# Getting Oriented

Welcome. This guide gets you set up and helps you find your way around.

## Environment Setup

1. [Setup step with command]
2. Start the app:
   ```bash
   npm run dev
   ```
3. Confirm at http://localhost:3000

## Reading the Codebase

### Where to Start

Work through these in order:
1. `src/core/` — [What you'll learn and why it's the right starting point]
2. `src/services/orders/` — [A reference implementation that shows the patterns in action]
3. `docs/guides/architecture.md` — [The bigger picture]

### Core Abstractions

| Concept | What It Is | Where It Lives |
|---------|------------|----------------|
| [Concept 1] | [Brief explanation] | `src/path/` |
| [Concept 2] | [Brief explanation] | `src/path/` |

### High-Level Architecture

[2-3 paragraph summary. Point to the full architecture doc for depth.]

See [Architecture Overview](./guides/architecture.md) for the complete picture.

## Starter Tasks

### Task 1: [Something small and achievable]

This gets you comfortable with [area/skill].

1. [Step]
2. [Step]
3. [Step]

### Task 2: [Something slightly larger]

This introduces [area/skill].

## Finding Things

| When you need to... | Look in... |
|---|---|
| Understand a past decision | `docs/decisions/` |
| Add a new service | `docs/how-to/add-service.md` |
| Browse the API | Generated docs at `/api-docs` |
| Check config options | `config.schema.json` |
| Review team conventions | `docs/conventions/` |

## Getting Unstuck

- [Chat channel or contact]
- [Where documentation lives]
- [Pairing opportunities or office hours]
```
