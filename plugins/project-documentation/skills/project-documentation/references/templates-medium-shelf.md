# Templates: Medium Shelf Life, Reference, and Supporting Docs

Templates for documentation that blends durable framing with breadcrumbs to current state, plus supporting documents every project needs.

## Contents

- [Medium Shelf Life](#medium-shelf-life)
  - [Architecture Overview](#architecture-overview)
  - [How-To Guide](#how-to-guide)
- [Short Shelf Life (Prefer Auto-Generation)](#short-shelf-life-prefer-auto-generation)
- [Supporting Documents](#supporting-documents)
  - [Troubleshooting](#troubleshooting)
  - [CONTRIBUTING.md](#contributingmd)
  - [SECURITY.md](#securitymd)

---

## Medium Shelf Life

These blend durable framing with breadcrumbs to current state.

### Architecture Overview

Describes the system's shape and the reasoning behind it. Documents the *structure*, breadcrumbs the *specifics*.

```markdown
# Architecture

How the system is structured and why.

## Bird's Eye View

[2-3 paragraphs describing the system at a high level]

```
[Conceptual diagram — boxes and arrows showing relationships,
not a code-level class or module diagram]
```

## Components

### [Component Name]

**Role**: [What problem this component addresses]

**Owns**:
- [Responsibility 1]
- [Responsibility 2]

**Design context**: See [ADR-NNNN](../decisions/NNNN-title.md)

**Code**: See `src/component/`

### [Next Component]

[Same structure...]

## How Data Moves

[Describe the conceptual flow of data through the system]

For current implementation:
- Ingestion: See `src/ingestion/`
- Processing: See `src/processing/`
- Storage: See `src/storage/`

## External Integrations

| System | Why We Integrate | Contract |
|--------|-----------------|----------|
| [External system] | [Business reason] | `src/integrations/system/` |

## Guardrails

- [Constraint 1]: [Why it exists]
- [Constraint 2]: [Why it exists]

## Key Decisions

- [ADR-0001: Title](../decisions/0001-title.md)
- [ADR-0002: Title](../decisions/0002-title.md)
```

---

### How-To Guide

Task-focused instructions. Documents the *process*, breadcrumbs the *moving parts*.

```markdown
# How to [Do the Thing]

When you need to [situation], follow these steps.

## Before You Start

- [Prerequisite]
- [Prerequisite]

## Steps

### 1. [Action Verb + Object]

[Brief context if needed]

```bash
command
```

### 2. [Action Verb + Object]

Update the configuration as needed.
See `config.schema.json` for the available settings.

### 3. [Action Verb + Object]

[Continue...]

### 4. Verify It Worked

```bash
verification command
```

You should see [expected result].

## Further Reading

- Working examples: `src/path/`
- Configuration details: `config.schema.json`
- Related guide: [Link]
```

---

## Short Shelf Life (Prefer Auto-Generation)

Reference material (API specs, CLI docs, config catalogs) changes with every code change. Prefer:

1. **Generated documentation** from code annotations (JSDoc, XML doc comments, OpenAPI, etc.)
2. **Schema files** as the authoritative source (`config.schema.json`, `.env.example`)
3. **Well-named code** with inline comments

If you must write reference docs by hand, keep them thin and point to the real source:

```markdown
# Configuration Reference

The application reads settings from environment variables and `config.json`.

For the complete list of options, defaults, and validation rules:
- Schema: `config.schema.json`
- Example: `config.example.json`

## Commonly Adjusted Settings

| Setting | Purpose |
|---------|---------|
| `PORT` | HTTP listener port |
| `LOG_LEVEL` | Verbosity (debug, info, warn, error) |

For the full set, consult the schema.
```

---

## Supporting Documents

### Troubleshooting

```markdown
# Troubleshooting

Fixes for common issues.

## [Problem Category]

### Symptom: [What the user sees]

**Why it happens**: [Root cause]

**Fix**:
```bash
fix command
```

Or check `src/path/` for [relevant context].

---

### [Next problem]

[Same structure...]

## Still Stuck?

1. Search [existing issues](link)
2. Check [discussions](link)
3. File an issue with: version, OS, reproduction steps
```

---

### CONTRIBUTING.md

```markdown
# Contributing

## Quick Version

1. Fork and clone
2. Branch: `git checkout -b feature/your-change`
3. Code and test: `npm test`
4. Submit a PR

## Local Development

```bash
git clone https://github.com/YOUR_FORK/REPO.git
cd REPO
npm install
npm run dev
```

## Standards

See [Conventions](./docs/conventions/) for code style and patterns.

## PR Expectations

1. Update docs if behavior changes
2. Add tests for new functionality
3. CI must pass
4. Request review from a maintainer
```

---

### SECURITY.md

```markdown
# Security

## Reporting a Vulnerability

**Do not open a public issue.**

Email: security@example.com

Include:
- What you found
- How to reproduce it
- Potential impact

We'll acknowledge within 48 hours.

## Supported Versions

| Version | Status |
|---------|--------|
| 2.x | Supported |
| 1.x | Security fixes only |
| < 1.0 | End of life |
```
