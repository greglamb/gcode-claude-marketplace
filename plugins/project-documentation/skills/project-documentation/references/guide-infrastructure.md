# Infrastructure Documentation Guide

How to apply the shelf life framework to cloud, IaC, networking, and observability documentation.

## Contents

- [Long Shelf Life — Write Fully](#long-shelf-life--write-fully)
- [Medium Shelf Life — Write and Link](#medium-shelf-life--write-and-link)
- [Short Shelf Life — Breadcrumb Only](#short-shelf-life--breadcrumb-only)
- [Runbooks](#runbooks)
- [Recommended Doc Layout](#recommended-doc-layout)
- [Completeness Checklist](#completeness-checklist)

---

## Long Shelf Life — Write Fully

### When to Write a Decision Record

Write an ADR when:
- Picking a cloud provider or region
- Choosing between compute services (e.g., Fargate vs. K8s vs. VMs)
- Defining high availability or disaster recovery strategy
- Designing the network topology
- Drawing security boundaries
- Selecting IaC tooling (Terraform, CDK, Pulumi, etc.)

**Example titles**: ADR-0001: ECS Fargate for containerized workloads, ADR-0002: Active-passive DR across two regions, ADR-0003: Hub-and-spoke network design, ADR-0004: Terraform with remote state in S3

### Conceptual Guide Content

Explain how to reason about the infrastructure:

```markdown
# Infrastructure: How to Think About It

## Environments

Three tiers, each with a distinct purpose:
- **Dev**: Disposable. Rebuilt often. Minimal redundancy.
- **Staging**: Mirrors production topology for validation.
- **Production**: Multi-AZ, auto-scaling, full observability.

## Network Model

Every environment uses a hub-and-spoke layout:
- The hub hosts shared services (DNS resolution, egress firewall)
- Each environment is a spoke with its own isolated VPC
- Traffic between spokes routes through the hub

## How Changes Ship

Infrastructure changes follow the same review discipline as code:
Code → Pull Request → Plan Review → Merge → Apply (one environment at a time)

See `/infra/` for the Terraform modules.
```

### Conventions Worth Documenting

- Resource naming patterns: `{project}-{env}-{type}-{region}`
- Tagging requirements and expected values
- IaC organization: module structure, state file management, variable conventions
- Environment differences: what diverges from production parity, and why

---

## Medium Shelf Life — Write and Link

| Topic | What to Write | Where to Breadcrumb |
|---|---|---|
| Network topology | High-level shape and rationale | `/infra/modules/network/` |
| Security controls | Categories and philosophy | AWS Config rules, SCPs |
| Observability approach | What we monitor and why | `/infra/modules/monitoring/` |
| Backup strategy | RTO/RPO targets | AWS Backup policy config |

**Example:**

```markdown
## Observability Strategy

We instrument at three levels:
1. **Infrastructure**: Container health, network reachability, disk/memory pressure
2. **Application**: Request throughput, error rates, response latency (p50/p95/p99)
3. **Business**: Transaction volume, active user count, conversion rate

Critical alerts (P1) page via PagerDuty. Everything else goes to email.

See `/infra/modules/monitoring/` for the alert definitions.
See CloudWatch > Alarms for current alert state.
```

---

## Short Shelf Life — Breadcrumb Only

| Don't Write Prose About | Breadcrumb To |
|---|---|
| Deployed resource inventory | `aws resourcegroupstaggingapi get-resources --tag-filters Key=project,Values=NAME` |
| Current IP allocations | Terraform state or cloud console |
| Cost breakdown | Cloud provider cost explorer |
| Live alert status | CloudWatch / Datadog / Grafana dashboard |
| Secrets | Secret manager (never document values) |
| Current scaling parameters | Auto-scaling configuration |

**Breadcrumb phrasing:**

```markdown
# Durable
Resources follow the naming convention `{project}-{env}-{type}`.
To list what's deployed:
`aws resourcegroupstaggingapi get-resources --tag-filters Key=project,Values=myapp`

# Fragile
The following resources are currently deployed:
| Name | Type | Size |
| myapp-prod-rds | PostgreSQL | db.r6g.large |
...
```

---

## Runbooks

Operational procedures have a long shelf life because they document *how to respond*, not *what currently exists*. Write these thoroughly:

- **Scaling**: When to scale, how, and how to verify
- **Incident response**: Triage steps, escalation paths, communication templates
- **Infrastructure deployment**: How to roll out IaC changes safely
- **Rotation tasks**: Certificate renewal, secret rotation, key rotation
- **DR procedures**: Failover steps, failback steps, validation

---

## Recommended Doc Layout

```
/docs/
├── decisions/
│   ├── 0001-cloud-region.md
│   ├── 0002-dr-strategy.md
│   └── 0003-network-design.md
├── guides/
│   └── infrastructure.md            # Conceptual guide
├── runbooks/
│   ├── scaling.md
│   ├── incident-response.md
│   ├── infra-deployment.md
│   └── dr-failover.md
└── conventions/
    └── infrastructure.md            # Naming, tagging, IaC patterns

/infra/                              # IaC source of truth
├── modules/
├── environments/
└── README.md                        # Signpost to /docs/
```

---

## Completeness Checklist

- [ ] ADRs cover cloud/region/service selections
- [ ] Conceptual guide explains network topology and environment model
- [ ] Naming and tagging conventions are documented
- [ ] Runbooks exist for scaling, DR, incidents, and deployment
- [ ] IaC repo README points to `/docs/` for context
- [ ] No resource inventories in prose (breadcrumb to cloud tooling or Terraform state)
- [ ] Access patterns and credential management approach documented
