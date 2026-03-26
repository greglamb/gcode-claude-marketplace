# Data Documentation Guide

How to apply the shelf life framework to databases, schemas, pipelines, and data operations.

## Contents

- [Long Shelf Life — Write Fully](#long-shelf-life--write-fully)
- [Medium Shelf Life — Write and Link](#medium-shelf-life--write-and-link)
- [Short Shelf Life — Breadcrumb Only](#short-shelf-life--breadcrumb-only)
- [Schema Documentation Philosophy](#schema-documentation-philosophy)
- [Data Ops Runbooks](#data-ops-runbooks)
- [Recommended Doc Layout](#recommended-doc-layout)
- [Completeness Checklist](#completeness-checklist)

---

## Long Shelf Life — Write Fully

### When to Write a Decision Record

Write an ADR when:
- Choosing database technology (relational vs. document vs. graph vs. polyglot)
- Defining data retention and archival policy
- Establishing PII and sensitive data handling rules
- Picking a consistency model
- Designing a sharding or partitioning strategy
- Choosing ETL vs. ELT, batch vs. streaming

**Example titles**: ADR-0001: PostgreSQL on managed hosting for transactional workloads, ADR-0002: Event sourcing for audit-sensitive domains, ADR-0003: 7-year retention with annual cold-tier archival, ADR-0004: Column-level encryption for personally identifiable fields

### Conceptual Guide Content

Explain how to reason about the data architecture:

```markdown
# Data Architecture: How to Think About It

## Data Zones

The system organizes data into three zones:
- **Transactional**: User records, orders, inventory — the live operational state (PostgreSQL)
- **Analytical**: Aggregated metrics, reports, trend data (read replicas or warehouse)
- **Event Log**: Immutable record of state changes for audit and integration (event store → archive)

## How Data Flows

1. User actions produce transactional writes
2. Change events propagate to the event bus
3. Downstream services and analytics consume events asynchronously
4. Scheduled jobs materialize analytical views

## Ownership Boundaries

Each service owns its own data store:
- Order Service owns the `orders` schema
- Identity Service owns the `users` schema
- Cross-service reads go through published events or APIs — never through direct database access

See `src/*/migrations/` for current schemas.
```

### Conventions Worth Documenting

- Migration discipline: Tooling choice, file naming, review expectations
- Naming standards: Table, column, index, and constraint naming patterns
- Data classification: How to label PII, internal, and public data
- Connection patterns: Pooling strategy, timeout values, retry behavior

---

## Medium Shelf Life — Write and Link

| Topic | What to Write | Where to Breadcrumb |
|---|---|---|
| Domain model | High-level entity relationships | ORM models or schema files |
| Data flow diagram | Conceptual pipeline shape | Implementation code |
| Security model | What's protected and why | Encryption and access config |
| Backup approach | Recovery time/point objectives | Backup service policies |

**Example:**

```markdown
## Data Protection Model

- **At rest**: Transparent encryption on all database volumes
- **In transit**: TLS 1.2+ enforced on all connections
- **PII fields**: Additional application-level encryption on designated columns
- **Access control**: Each service gets a scoped database account with least privilege

PII columns are tagged in code with a `@sensitive` annotation.
See `src/domain/entities/` for the current field classifications.
```

---

## Short Shelf Life — Breadcrumb Only

| Don't Write Prose About | Breadcrumb To |
|---|---|
| Current table/column inventory | Migration files or `information_schema` |
| Row counts or data volumes | Database statistics views or monitoring dashboards |
| Index definitions | Migration files or database catalog |
| Current storage consumption | Cloud monitoring metrics |
| Connection strings | Secret manager references |
| Backup status | Backup service dashboard |

**Breadcrumb phrasing:**

```markdown
# Durable
The Order domain uses event sourcing for full auditability.
See `src/orders/events/` for event type definitions and
`src/orders/migrations/` for the current storage schema.

# Fragile
The orders database contains these tables:
| Table | Columns | Purpose |
| orders | id, customer_id, status... | Order headers |
...
```

---

## Schema Documentation Philosophy

Let the code be the documentation:

```typescript
/**
 * A customer order.
 *
 * Orders become immutable after confirmation. All subsequent
 * state transitions are captured as OrderEvents.
 */
export class Order {
  // Well-named properties with doc comments ARE the schema docs
}
```

When extra context is needed beyond what code comments provide, document the *model* — the conceptual behavior — not the *schema* — the column layout:

```markdown
## Order Lifecycle

Orders progress through a state machine:
Draft → Confirmed → Fulfilled → Closed
     → Cancelled (only from Draft or Confirmed)

Each transition emits a domain event. See `src/orders/events/` for the event catalog.
```

---

## Data Ops Runbooks

These are durable procedures — write them thoroughly:

- **Migration deployment**: Safe steps for applying schema changes
- **Data pipeline operations**: Running, monitoring, and recovering ETL/ELT jobs
- **Point-in-time restore**: How to restore a database to a specific moment
- **Production data corrections**: Safe patterns for fixing data in production

---

## Recommended Doc Layout

```
/docs/
├── decisions/
│   ├── 0001-database-selection.md
│   ├── 0002-event-sourcing.md
│   └── 0003-retention-policy.md
├── guides/
│   └── data-architecture.md          # Conceptual guide
├── runbooks/
│   ├── migrations.md
│   ├── data-restore.md
│   └── pipeline-operations.md
└── conventions/
    └── data.md                       # Naming, classification, connections

/src/*/migrations/                    # Schema source of truth
/src/*/entities/                      # Model source of truth
```

---

## Completeness Checklist

- [ ] ADRs cover database technology selections
- [ ] ADR covers data retention and archival approach
- [ ] Conceptual guide explains data zones and flow
- [ ] PII handling approach is documented
- [ ] Migration conventions are written down
- [ ] No schema dumps in prose (breadcrumb to migrations)
- [ ] Runbooks cover migrations, restores, and pipeline ops
- [ ] Connection and pooling patterns are documented
