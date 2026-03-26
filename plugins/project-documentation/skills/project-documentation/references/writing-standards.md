# Writing Standards

Rules for writing documentation that ages well. Drawn from industry-standard guides (Google Developer Docs, GitHub Docs, Microsoft Style Guide) with shelf-life-aware additions.

## Contents

- [Guiding Principle](#guiding-principle)
- [Shelf-Life-Aware Patterns](#shelf-life-aware-patterns)
- [Structure](#structure)
- [Formatting](#formatting)
- [Voice and Tone](#voice-and-tone)
- [Document Archetypes](#document-archetypes)
- [Pre-Publish Checklist](#pre-publish-checklist)

---

## Guiding Principle

Documentation should stay accurate because of how it's written, not because someone remembers to update it.

---

## Shelf-Life-Aware Patterns

### The Breadcrumb Technique

When the content you'd write has a short shelf life, point the reader to where the truth lives.

**Structure:**

```markdown
[One sentence framing what it is or why it matters].
See `path/to/authoritative-source` for [current details/options/implementations].
```

**In practice:**

```markdown
# Durable — describes the pattern, breadcrumbs the specifics
The notification system uses a pub/sub model with typed event channels.
See `src/events/channels/` for the channel definitions currently in use.

# Fragile — narrates specifics that'll change
The notification system has four event channels:
- UserChannel handles registration and profile updates
- OrderChannel handles order lifecycle events
- PaymentChannel handles payment processing events
- AdminChannel handles system administration events
```

```markdown
# Durable — links to the single source of truth
Tune the application using environment variables.
See `.env.example` for the full set of knobs and their defaults.

# Fragile — creates a second source of truth
The following environment variables control behavior:
| Variable | Default | Description |
| CACHE_TTL | 300 | Cache duration in seconds |
| MAX_WORKERS | 4 | Parallel worker threads |
...
```

### Content That Ages Well vs. Poorly

| Ages well — write fully | Ages poorly — breadcrumb |
|---|---|
| The reasoning behind a choice | The options currently available |
| How to conceptualize the system | What the system currently contains |
| Which patterns to follow | Current type signatures and schemas |
| What each component is *for* | What each component currently *does* in detail |

### Phrases That Signal Durability

These indicate content worth writing in full:

- "We chose X because..."
- "The guiding principle is..."
- "By convention, we..."
- "Think of it as..."
- "The boundary between X and Y is..."

### Phrases That Signal Fragility

These indicate content that should be a breadcrumb instead:

- "Currently, we have..."
- "The available options include..."
- "The endpoints are..."
- "The schema consists of..."
- "There are N instances of..."

### Diagrams That Last vs. Diagrams That Don't

Diagrams follow the same shelf life rules as prose. The key distinction is **conceptual diagrams** (durable) vs. **structural diagrams** (volatile).

**Durable diagrams** show relationships, flows, and boundaries at a conceptual level. They use labeled boxes and arrows, not class names or file paths. They survive refactoring because they describe *how things relate*, not *what things are named*.

```
Good: [Client] → [API Gateway] → [Auth Service] → [Domain Layer] → [Database]
Bad:  [Express Router] → [AuthMiddleware.ts] → [UserController.ts] → [PrismaClient]
```

**Volatile diagrams** show implementation structure — class hierarchies, module dependency graphs, database schemas. These go stale with every refactor. If you need them, generate them from code rather than maintaining them by hand.

**Mermaid guidance** (for inline diagrams):
- Use `graph` or `flowchart` for conceptual flows — these are durable
- Avoid `classDiagram` in docs — it duplicates what the code expresses and rots quickly
- `erDiagram` is acceptable in conceptual guides if it shows the *domain model* (entities and relationships) rather than the *physical schema* (tables and columns)
- `sequenceDiagram` is medium shelf life — the interaction pattern is usually stable, but participant names may drift. Use role names ("Auth Service") not implementation names ("CognitoAuthHandler")

**General rules**:
- Label diagram elements with *roles* and *purposes*, not *class names* or *file names*
- Keep diagrams to 5-10 elements. If you need more, you're probably at a level of detail that belongs in code
- When a diagram references implementation, add a breadcrumb: "For the current implementation of each component, see `src/services/`"

---

## Structure

### Lead with Purpose

The first sentence or two should answer: *What is this thing and why does it exist?*

```markdown
# Fragile — leads with current state
This service processes 15 event types from 3 upstream producers...

# Durable — leads with purpose
This service normalizes raw events from upstream producers into
a consistent domain event format for downstream consumers.
```

### Prerequisites

List what's needed with version constraints. Never assume prior setup.

```markdown
## Prerequisites

- Node.js 20+
- Docker Desktop
- AWS CLI v2 (authenticated)
```

### Procedural Steps

Numbered, one action per step, imperative mood.

```markdown
## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/org/repo.git
   cd repo
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the dev server:
   ```bash
   npm run dev
   ```

   You should see `Listening on http://localhost:3000`.
```

### Verification After Commands

Every command that produces output needs an expected-result line:

```markdown
3. Confirm it's working:
   ```bash
   my-tool --version
   ```
   You should see a version like `2.1.0`.
```

---

## Formatting

### Headers

Use ATX-style (`#`, `##`, `###`). Leave a blank line before headers, code fences, and lists.

### Code Fences

Always tag the language:

````markdown
```bash
npm install
```

```typescript
const settings: AppConfig = { port: 3000 };
```
````

### Inline Code

Use backticks for file names (`config.json`), paths (`src/core/`), commands (`npm test`), environment variables (`NODE_ENV`), and code identifiers (`processOrder()`).

### Placeholders

ALL_CAPS for values the reader must substitute:

```markdown
git remote add origin https://github.com/YOUR_ORG/YOUR_REPO.git
```

### Links

Inline style with descriptive text:

```markdown
See the [schema definition](./config.schema.json) for all options.
```

### Callouts (GitHub-Flavored)

Use sparingly — at most one per section:

```markdown
> [!NOTE]
> Helpful supplementary detail.

> [!WARNING]
> Something that could cause problems if missed.
```

---

## Voice and Tone

### Be Conversational

Read your docs aloud. Use contractions: *you'll*, *it's*, *don't*, *we've*.

| Stiff | Natural |
|---|---|
| "It is necessary to configure..." | "You'll need to configure..." |
| "One should ensure that..." | "Make sure..." |
| "The system shall..." | "The system..." |

### Use Imperative Mood for Instructions

Start steps with verbs: *Install*, *Configure*, *Run*, *Open*, *Verify*.

### Words to Avoid

| Word | Problem |
|---|---|
| just, simply | Minimizes difficulty — if it were simple, they wouldn't need docs |
| obviously, clearly | Makes the reader feel bad for not knowing |
| easy, easily | Subjective and often wrong |
| currently | Usually a signal you're about to narrate something volatile — breadcrumb instead |
| please | Unnecessary formality in technical instructions |

### Documenting Errors

State the cause, then the fix. No blame.

```markdown
# Blaming
If you get this error, you probably forgot to set up credentials.

# Constructive
This error appears when credentials aren't configured.
See the [authentication guide](./auth.md) or check `~/.config/tool/credentials`.
```

---

## Document Archetypes

Each document type serves one purpose. Don't blend them.

| Type | Purpose | Shelf Life |
|---|---|---|
| Decision Record (ADR) | Why a choice was made | Long |
| Conceptual Guide | How to think about the system | Long |
| Conventions Doc | Team-agreed patterns and rules | Long |
| Onboarding Guide | How to get oriented | Long |
| Runbook | Step-by-step operational procedure | Long |
| Architecture Overview | System shape and component roles | Medium |
| How-To Guide | Complete a specific task | Medium |
| README | Orient and direct | Medium |
| Reference | API/CLI/config specifics | Short (prefer auto-generation) |

---

## Before/After Gallery

Real rewrites showing how to apply these standards. Study the *what changed* and *why* — these are the judgment calls that make documentation durable.

### Rewrite 1: Inventory → Breadcrumb

**Before** (fragile — stale the moment a new service is added):
```markdown
## Microservices

The platform consists of five microservices:
1. **OrderService** — Handles order creation and lifecycle
2. **InventoryService** — Tracks stock levels
3. **PaymentService** — Processes payments via Stripe
4. **NotificationService** — Sends emails and push notifications
5. **ReportingService** — Generates analytics dashboards

Each service runs as a Docker container on ECS Fargate.
```

**After** (durable — survives service additions and removals):
```markdown
## Service Architecture

The platform is decomposed into single-responsibility services, each owning
its own data store and communicating through the event bus. Services are
deployed as containers on ECS Fargate.

See `src/services/` for the current service inventory and each service's
README for its specific responsibilities.
```

**What changed**: The *inventory* (which services exist) was replaced with the *principle* (single-responsibility, event-driven) and a breadcrumb. The principle will still be true in a year; the list of five services won't.

---

### Rewrite 2: Implementation Narration → Conceptual Explanation

**Before** (fragile — couples to class names and method signatures):
```markdown
## Authentication

The `AuthController` receives login requests and passes them to `AuthService.authenticate()`,
which calls `CognitoProvider.verifyToken()`. If verification succeeds, `JwtHelper.generateToken()`
creates a session token stored in `SessionRepository` backed by Redis. The token is returned
in the `Authorization` header.
```

**After** (durable — explains the flow without coupling to implementation):
```markdown
## Authentication

Login requests are validated against the identity provider and, on success,
produce a session token. Tokens are cached for fast subsequent validation.

The system uses a pluggable provider model, making it straightforward to
swap identity providers without changing the authentication flow.

See `src/auth/` for the current implementation. See ADR-0002 for why we
chose the pluggable approach.
```

**What changed**: Class names, method names, and technology specifics (Redis, Cognito) were removed. The *flow* and *design rationale* are what a developer needs to understand; the implementation details are one click away in the code.

---

### Rewrite 3: Stiff Tone → Conversational

**Before** (reads like a legal document):
```markdown
## Prerequisites

It is necessary to ensure that the following software components have been
installed and properly configured on the development workstation prior to
attempting to execute the application build process:

- Node.js runtime environment, version 20 or later
- Docker Desktop container management platform
- AWS Command Line Interface, properly authenticated
```

**After** (reads like a colleague helping you set up):
```markdown
## Prerequisites

You'll need these installed before getting started:

- Node.js 20+
- Docker Desktop
- AWS CLI (authenticated to the dev account)
```

**What changed**: 68 words → 26 words. Same information, no loss of clarity. Contractions ("You'll"), imperative framing, and version numbers inline.

---

### Rewrite 4: Blame → Constructive Error Doc

**Before** (makes the reader feel bad):
```markdown
### Connection Refused Error

If you see `ECONNREFUSED`, you probably forgot to start Docker before
running the application. This is a common mistake for new developers.
Simply run `docker compose up -d` and try again.
```

**After** (states cause and fix neutrally):
```markdown
### Connection Refused Error

`ECONNREFUSED` appears when the backing services aren't running.

Start them:
```bash
docker compose up -d
```

Then retry. If the error persists, check that the ports in `.env`
match your Docker Compose configuration.
```

**What changed**: Removed "you probably forgot" (blame), "common mistake" (condescension), and "simply" (minimizes difficulty). Added a next step for when the obvious fix doesn't work.

---

### Rewrite 5: Volatile Opening → Durable Opening

**Before** (leads with a number that changes):
```markdown
# Event Processing Service

This service processes 47 different event types from 5 upstream producers,
handling approximately 2.3 million events per day across 3 Kubernetes pods.
```

**After** (leads with purpose):
```markdown
# Event Processing Service

Normalizes raw events from upstream producers into a consistent domain
event format for downstream consumers. Designed for high throughput
with at-least-once delivery guarantees.

For current event type catalog, see `src/events/types/`.
For operational metrics, see the Grafana dashboard.
```

**What changed**: Numbers (47 types, 5 producers, 2.3M events, 3 pods) are all volatile — they'll be wrong next quarter. The purpose and design guarantees will still be accurate.

---

## Pre-Publish Checklist

### Shelf Life

- [ ] Volatile specifics breadcrumb to source instead of being written inline
- [ ] No "currently we have X, Y, Z" inventories that'll go stale
- [ ] Decision records exist for significant choices
- [ ] Conceptual content describes how to *think*, not what *exists*

### Structure

- [ ] Opening sentence answers "what is this and why does it exist?"
- [ ] Prerequisites listed with version constraints
- [ ] Procedural steps are numbered, one action each
- [ ] Expected output shown after commands that produce output

### Voice

- [ ] No forbidden words (just, simply, obviously, easy)
- [ ] Contractions used naturally
- [ ] Second person ("you") throughout
- [ ] Imperative mood for instructions

### Formatting

- [ ] Code fences include language tags
- [ ] Placeholders use ALL_CAPS
- [ ] Links are descriptive (not "click here")
- [ ] No shell prompts (`$`, `>`) inside code fences
