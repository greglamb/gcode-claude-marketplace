# Engineering Documentation Guide

How to apply the shelf life framework to codebase architecture, development environment, and engineering practices.

## Contents

- [Long Shelf Life — Write Fully](#long-shelf-life--write-fully)
- [Medium Shelf Life — Write and Link](#medium-shelf-life--write-and-link)
- [Short Shelf Life — Breadcrumb Only](#short-shelf-life--breadcrumb-only)
- [Dev Environment Runbook](#dev-environment-runbook)
- [Task-Based How-To Guides](#task-based-how-to-guides)
- [Recommended Doc Layout](#recommended-doc-layout)
- [Completeness Checklist](#completeness-checklist)

---

## Long Shelf Life — Write Fully

### When to Write a Decision Record

Write an ADR when:
- Selecting the primary language and framework
- Choosing an architectural pattern (layered, hexagonal, vertical slice, etc.)
- Defining the testing approach and coverage expectations
- Establishing the CI/CD strategy
- Picking frontend state management (if applicable)
- Selecting libraries for cross-cutting concerns (logging, auth, validation)

**Example titles**: ADR-0001: TypeScript with layered architecture, ADR-0002: React with TypeScript for the UI layer, ADR-0003: Testing pyramid targeting 80% line coverage, ADR-0004: GitHub Actions for CI/CD, ADR-0005: CQRS with dedicated command and query pipelines

### Conceptual Guide Content

Explain how to navigate and reason about the codebase:

```markdown
# Codebase: How to Think About It

## Architectural Layers

The project follows a layered architecture with inward-pointing dependencies:

```
src/
├── api/              # HTTP layer: routes, middleware, request/response
├── application/      # Use cases: commands, queries, orchestration
├── domain/           # Core: entities, value objects, domain events, interfaces
└── infrastructure/   # Adapters: database access, third-party clients
```

The dependency rule: outer layers depend on inner layers, never the reverse.
`api → application → domain ← infrastructure`

## Central Abstractions

- **Commands**: Operations that change state
- **Queries**: Operations that read state
- **Domain Events**: Notifications that something meaningful happened
- **Repositories**: Data access interfaces (defined in Domain, implemented in Infrastructure)

## Finding Your Way

| I need to... | Start in... |
|---|---|
| Expose a new endpoint | `src/api/routes/` |
| Add business logic | `src/application/features/` |
| Define a domain concept | `src/domain/entities/` |
| Integrate with an external system | `src/infrastructure/services/` |

## The Feature Pattern

Adding a new capability follows a repeatable path:
1. Create a feature folder in `src/application/features/{name}/`
2. Define the command or query and its handler
3. Wire up the API route in `src/api/routes/`
4. Write tests in `tests/{layer}/`

See `src/application/features/orders/` as a reference implementation.
```

### Conventions Worth Documenting

- Code organization: Folder structure philosophy and feature folder patterns
- Naming rules: Files, classes, methods, interfaces
- Dependency injection: How services are registered and resolved
- Error handling: Exception hierarchy and handling strategy
- Logging: Structured logging conventions, log levels, what to log

---

## Medium Shelf Life — Write and Link

| Topic | What to Write | Where to Breadcrumb |
|---|---|---|
| Project structure | High-level map and rationale | Actual directory tree |
| Build pipeline | What it does and why | Pipeline config files |
| Test layout | Strategy and organization approach | Test project structure |
| Configuration approach | Layering model | Config files and schema |

**Example:**

```markdown
## Configuration Layering

Settings are resolved in order — each layer overrides the previous:
1. `.env.defaults` — Sensible defaults for local development
2. `.env.{environment}` — Environment-specific overrides
3. Environment variables — Deployment-time values
4. Secret manager — Sensitive values (never in files)

See `.env.example` for the available settings.
Secret names are in the deployment runbook.
```

---

## Short Shelf Life — Breadcrumb Only

| Don't Write Prose About | Breadcrumb To |
|---|---|
| Dependency list and versions | `package.json` or the equivalent manifest |
| Linter and formatter rules | `.eslintrc`, `.editorconfig`, `.prettierrc` |
| CI pipeline steps | `.github/workflows/` or pipeline config |
| Test coverage numbers | CI dashboard or coverage report |
| Feature flag inventory | Feature flag service dashboard |

**Breadcrumb phrasing:**

```markdown
# Durable
The project uses a layered architecture with feature folders.
See `src/` for the current layout.
For a complete example of the pattern, explore `src/application/features/orders/`.

# Fragile
## Project Structure

The codebase contains these modules:
- myapp-api (Express)
  - routes/
    - orders.router.ts
    - users.router.ts
...
```

---

## Dev Environment Runbook

A durable, procedural document:

```markdown
# Setting Up Your Development Environment

## What You'll Need

- Node.js 20 LTS
- Docker Desktop
- Cloud CLI (authenticated to the development account)

## First-Time Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/org/repo.git
   cd repo
   ```

2. Create your local env file:
   ```bash
   cp .env.example .env
   ```

3. Start the backing services:
   ```bash
   docker compose up -d
   ```

4. Install and build:
   ```bash
   npm install
   npm run build
   ```

5. Validate everything works:
   ```bash
   npm test
   ```
   All tests should pass.

6. Start the application:
   ```bash
   npm run dev
   ```
   Open http://localhost:3000/api-docs

## Everyday Commands

```bash
docker compose up -d              # Start backing services
npm run dev                       # Run the app
npm test                          # Run all tests
npm test -- --grep "orders"       # Run a subset of tests
```
```

---

## Task-Based How-To Guides

```markdown
# How to Add a Feature

1. Create a feature folder:
   ```
   src/application/features/{feature-name}/
   ```

2. Define the command or query:
   ```typescript
   export interface CreateWidgetCommand { name: string; category: string; }
   ```

3. Implement the handler:
   ```typescript
   export class CreateWidgetHandler implements ICommandHandler<CreateWidgetCommand, string> { ... }
   ```

4. Add an API route:
   ```typescript
   router.post('/widgets', async (req, res) => { /* delegate to handler */ });
   ```

5. Write tests in `tests/application/features/{feature-name}/`

Use `src/application/features/orders/` as your reference.
```

---

## Recommended Doc Layout

```
/docs/
├── decisions/
│   ├── 0001-language-and-architecture.md
│   ├── 0002-frontend-framework.md
│   └── 0003-testing-strategy.md
├── guides/
│   ├── codebase.md                    # Conceptual guide
│   └── dev-setup.md                   # Environment runbook
├── how-to/
│   ├── add-feature.md
│   ├── add-endpoint.md
│   └── run-migrations.md
└── conventions/
    ├── coding-standards.md
    └── git-workflow.md

/src/                                  # Code is the source of truth
/.github/workflows/                    # Pipeline config is the source of truth
```

---

## Completeness Checklist

- [ ] ADRs cover language, architecture, and testing decisions
- [ ] Codebase conceptual guide exists
- [ ] Dev setup runbook is complete and recently tested
- [ ] Coding conventions and git workflow are documented
- [ ] Common tasks have how-to guides
- [ ] No dependency inventories in prose (breadcrumb to package manifest)
- [ ] No project tree dumps in prose (breadcrumb to actual source)
- [ ] Reference implementations are identified for recurring patterns
