# README Templates: Applications and Libraries

Copy-paste README templates for application and library projects. Every template follows the signpost principle: orient the reader, prove it works, direct them elsewhere.

For infrastructure, deployment, and serverless READMEs, see [templates-readme-ops.md](templates-readme-ops.md).

## Contents

- [Starter README](#starter-readme)
- [Node.js / TypeScript Application](#nodejs--typescript-application)
- [npm Package / Reusable Library](#npm-package--reusable-library)
- [React Frontend](#react-frontend)
- [Web API (Express/Koa/Fastify)](#web-api-expresskoafastify)
- [Database Project (PostgreSQL)](#database-project-postgresql)

---

## Starter README

The minimal viable README. Works for anything.

```markdown
# Project Name

> One sentence: what this does and for whom.

## 🚀 Quick Start

```bash
git clone https://github.com/ORG/REPO.git
cd REPO
npm install
npm start
```

Visit http://localhost:3000 to confirm it's running.

## 🎯 What It Does

- [Key outcome 1]
- [Key outcome 2]
- [Key outcome 3]

## 🧑‍💻 Example

```bash
tool do-thing --flag value
```

## 📚 Docs

- [Developer Guide](./docs/guides/developer-guide.md) — Mental model for the system
- [How-To Guides](./docs/how-to/) — Task walkthroughs
- [Architecture](./docs/guides/architecture.md) — System design and rationale
- [Decisions](./docs/decisions/) — ADRs for key choices
```

---

## Node.js / TypeScript Application

```markdown
# Project Name

> One sentence describing the application and its audience.

[![CI](https://img.shields.io/github/actions/workflow/status/org/repo/ci.yml)]()

## 🚀 Quick Start

```bash
git clone https://github.com/org/repo.git
cd repo
npm install
npm run build
npm start
```

You should see `Server running at http://localhost:3000`.

## 🎯 What It Does

- [Primary capability]
- [Secondary capability]

## 🧑‍💻 Example

```typescript
import { doWork } from 'project-name';

const output = doWork({ input: 'data' });
```

## 📚 Docs

| Looking for... | Go to... |
|---|---|
| How the system works | [Developer Guide](./docs/guides/) |
| Step-by-step tasks | [How-To Guides](./docs/how-to/) |
| Why we chose X | [Decisions](./docs/decisions/) |
| Config options | [`config.schema.json`](./config.schema.json) |
```

---

## npm Package / Reusable Library

```markdown
# package-name

> One sentence: what problem this package solves.

[![npm](https://img.shields.io/npm/v/package-name)]()

## Install

```bash
npm install package-name
```

## 🚀 Quick Start

```typescript
import { transform } from 'package-name';

const result = transform({ source: 'input' });
console.log(result);
```

## 🎯 What It Does

- [Core capability]
- [Secondary capability]

## 📚 Docs

- [API Reference](./docs/api.md) — Exports and configuration
- [Examples](./examples/) — Real-world usage patterns
- [Migration](./docs/migration.md) — Version upgrade guide
```

---

## React Frontend

```markdown
# App Name

> One sentence: what this app does and who uses it.

[![CI](https://img.shields.io/github/actions/workflow/status/org/repo/ci.yml)]()

## 🚀 Quick Start

```bash
git clone https://github.com/org/repo.git
cd repo
npm install
npm run dev
```

Open http://localhost:5173 to see the app.

## 🎯 What It Does

- [Primary user-facing capability]
- [Secondary capability]

## 🧑‍💻 Development

```bash
npm run dev          # Dev server
npm run build        # Production build
npm run test         # Tests
npm run lint         # Linting
```

## 📁 Layout

```
src/
├── components/      # Shared UI components
├── pages/           # Route-level views
├── hooks/           # Custom hooks
├── services/        # API clients
└── types/           # TypeScript definitions
```

See [Developer Guide](./docs/guides/) for component patterns.

## 📚 Docs

| Looking for... | Go to... |
|---|---|
| Component conventions | [Developer Guide](./docs/guides/) |
| Adding a feature | [How-To Guides](./docs/how-to/) |
| State management rationale | [Decisions](./docs/decisions/) |
| Environment config | [`.env.example`](./.env.example) |
```

---

## Web API (Express/Koa/Fastify)

```markdown
# Project Name

> One sentence: what this API provides.

[![CI](https://img.shields.io/github/actions/workflow/status/org/repo/ci.yml)]()
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue)]()

## 🚀 Quick Start

```bash
git clone https://github.com/org/repo.git
cd repo
npm install
npm run dev
```

Browse to http://localhost:3000/api-docs for the Swagger UI.

## 🎯 What It Does

- [Primary API capability]
- [Secondary capability]

## 🧑‍💻 Example

```bash
curl http://localhost:3000/api/v1/items
```

## 📚 Docs

- [API Reference](http://localhost:3000/api-docs) — Auto-generated from code
- [Architecture](./docs/guides/architecture.md)
- [Deployment](./docs/runbooks/deployment.md)
```

---

## Database Project (PostgreSQL)

```markdown
# Database Name

> One sentence: what domain this database supports.

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16+-blue)]()

## 🚀 Quick Start

```bash
git clone https://github.com/org/repo.git
cd repo
npm install

# Apply migrations
npx prisma migrate dev
# Or with raw SQL:
# psql -h localhost -U postgres -d DB_NAME -f migrations/001_initial.sql
```

## 🎯 What It Does

- [Primary schema domain]
- [Key data relationships]

## 📚 Docs

- [Data Model](./docs/guides/data-model.md) — Conceptual overview
- [Migration Strategy](./docs/conventions/migrations.md)
- [Deployment](./docs/runbooks/deployment.md)
```
