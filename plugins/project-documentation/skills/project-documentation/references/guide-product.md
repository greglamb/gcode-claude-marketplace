# Product Documentation Guide

How to apply the shelf life framework to feature documentation, user journeys, analytics, and release processes.

## Contents

- [Long Shelf Life — Write Fully](#long-shelf-life--write-fully)
- [Medium Shelf Life — Write and Link](#medium-shelf-life--write-and-link)
- [Short Shelf Life — Breadcrumb Only](#short-shelf-life--breadcrumb-only)
- [End-User Docs — A Separate Concern](#end-user-docs--a-separate-concern)
- [Release Process Runbook](#release-process-runbook)
- [Recommended Doc Layout](#recommended-doc-layout)
- [Completeness Checklist](#completeness-checklist)

---

## Long Shelf Life — Write Fully

### When to Write a Decision Record

Write an ADR when:
- Scoping what problem the product will (and won't) solve
- Defining user roles and the permission model
- Choosing an analytics or telemetry approach
- Establishing feature flag strategy
- Making a significant UX pattern choice
- Deciding between build and buy for a capability

**Example titles**: ADR-0001: B2B self-service focus (not B2C), ADR-0002: Three-tier role model (Admin, Manager, Operator), ADR-0003: Product analytics via managed telemetry service, ADR-0004: Feature flags via LaunchDarkly

### Conceptual Guide Content

Explain what the product does, for whom, and how to think about it:

```markdown
# Product: How to Think About It

## The Problem We Solve

[Organization] manually processes thousands of [items] monthly.
This application automates the core workflow, cutting processing
time from hours to minutes while maintaining audit compliance.

## Who Uses It

| Role | Primary Activities | Success Looks Like |
|---|---|---|
| Operator | Daily batch processing, data validation | High throughput, low error rate |
| Supervisor | Approvals, exception handling, reporting | SLA adherence |
| Administrator | User management, system configuration | Enabling role (no direct KPIs) |

## Core Journeys

### Daily Processing (Operator)
1. Log in, review the work queue
2. Validate each item, approve or flag
3. Submit the completed batch

### Exception Handling (Supervisor)
1. Review items flagged by operators
2. Investigate and decide: approve, reject, or escalate

## What the Product Provides

- **Automated validation**: Rules engine catches common data issues upfront
- **Batch processing**: Efficient handling of high-volume workloads
- **Audit trail**: Every action is recorded for compliance
- **Dashboards**: Real-time operational views and scheduled reports

## Explicit Non-Goals

- Consumer self-service (scoped out per ADR-0001)
- Real-time streaming (batch processing is sufficient for the use case)
- Mobile app (this is a desktop-centric workflow)
```

### Conventions Worth Documenting

- Feature naming: How features are labeled in the UI and in code
- Role definitions: What each role can and cannot do
- Release cadence: How features move from development to production
- Feature flag naming: Key naming patterns and lifecycle expectations

---

## Medium Shelf Life — Write and Link

| Topic | What to Write | Where to Breadcrumb |
|---|---|---|
| Feature areas | Capability categories | Backlog tool (Jira/Linear) or feature flags |
| Permission matrix | Role capabilities overview | Admin UI or authorization config |
| Analytics instrumentation | What we measure and why | Analytics dashboard |
| Release history | Summary of what changed | CHANGELOG.md or GitHub releases |

**Example:**

```markdown
## Capability Overview

The application is organized into four areas:
- **Processing**: Core workflow automation
- **Approvals**: Supervisor review and sign-off
- **Reporting**: Dashboards and data exports
- **Administration**: User and system configuration

For the current feature set within each area, see the backlog filtered by Epic.
For feature availability by environment, check the feature flag dashboard.
```

---

## Short Shelf Life — Breadcrumb Only

| Don't Write Prose About | Breadcrumb To |
|---|---|
| Feature catalog | Backlog tool (epics) or feature flag list |
| Current metric values | Analytics dashboard |
| Active user list | Admin UI or identity provider |
| Live configuration | Admin UI or config service |
| Known bugs and issues | Issue tracker |
| Full release history | CHANGELOG.md or release tags |

**Breadcrumb phrasing:**

```markdown
# Durable
The application supports three user roles with distinct permission scopes.
See the Admin > Roles screen for current permission assignments.
See ADR-0002 for the reasoning behind the role model.

# Fragile
## Features

### Processing Module
The processing module includes:
- Automated data validation
- Duplicate detection
- CSV and Excel batch upload
- Queue management
...
```

---

## End-User Docs — A Separate Concern

Documentation for end users (help articles, training materials, tooltips) is fundamentally different from developer documentation:

| Developer Docs | End-User Docs |
|---|---|
| How it's built | How to use it |
| Lives in the repo | Lives in a help system or wiki |
| Audience: engineers | Audience: operators, supervisors, admins |
| Shelf life framework applies | Different authoring rules |

If end-user documentation exists or is planned:
- Keep it separate from `/docs/` (which is for the engineering team)
- Link to its location from the product conceptual guide
- Consider a dedicated tool (help center, knowledge base, in-app guides)

---

## Release Process Runbook

```markdown
## Shipping a Feature

1. Feature is developed behind a flag (disabled in production)
2. Deployed to staging; flag enabled for testing
3. QA validates in staging
4. Deployed to production; flag remains disabled
5. Flag enabled for a beta cohort
6. Gradual rollout: 10% → 50% → 100%
7. Flag is removed from code after 30 days of stability

See the feature flag dashboard for current flag states.
See `.github/workflows/deploy.yml` for the deployment pipeline.
```

---

## Recommended Doc Layout

```
/docs/
├── decisions/
│   ├── 0001-product-scope.md
│   ├── 0002-role-model.md
│   └── 0003-analytics-approach.md
├── guides/
│   └── product.md                     # Conceptual guide
├── runbooks/
│   └── feature-release.md
└── conventions/
    └── product.md                     # Naming, release cadence, flag lifecycle

External (breadcrumb to these):
- Backlog tool: Current features and roadmap
- Feature flag dashboard: Flag states per environment
- Analytics dashboard: Live metrics
- Help center: End-user documentation
```

---

## Completeness Checklist

- [ ] Product conceptual guide explains what, who, and why
- [ ] Core user journeys are documented
- [ ] Role model and rationale are captured (ADR)
- [ ] Feature release process is documented as a runbook
- [ ] No feature catalogs in prose (breadcrumb to backlog/flags)
- [ ] No live metrics in prose (breadcrumb to dashboards)
- [ ] Analytics strategy is documented (what we measure and why)
- [ ] End-user docs location is identified (if separate)
- [ ] Known limitations are captured somewhere findable
