# Example: Completed ADR

This is what a finished ADR looks like — not a template, but a real document with real reasoning. Use it to calibrate the depth, tone, and judgment expected in your own ADRs.

---

# ADR-0003: PostgreSQL for Transactional Data Storage

**Status**: Accepted

**Decided**: 2025-09-12

**Participants**: Sarah Chen (Tech Lead), Marcus Rivera (Backend Lead), DevOps team

## Situation

The order management service needs a primary data store. We process roughly 50,000 orders per day with peaks of 200/second during promotions. The data is highly relational — orders reference customers, products, inventory, and payment records, with strong consistency requirements (we can't sell inventory we don't have).

We're an AWS shop, so managed options are preferred. The team has deep SQL experience but limited NoSQL experience. Our compliance obligations require ACID transactions for financial records.

## Resolution

We'll use PostgreSQL on Amazon RDS, Multi-AZ deployment, starting with a db.r6g.xlarge instance class.

## Reasoning

### Alternatives Evaluated

**Option A: Amazon DynamoDB**
- Upside: Fully managed, auto-scaling, predictable latency at any scale
- Upside: Native AWS integration with IAM, CloudWatch, EventBridge
- Downside: Our data is deeply relational — modeling order → line items → inventory → payments in DynamoDB requires denormalization that makes consistency hard to guarantee
- Downside: Team has no DynamoDB experience; the learning curve for data modeling is steep and errors are expensive
- Downside: Ad-hoc analytical queries are difficult without piping everything to another store

**Option B: PostgreSQL on Amazon RDS** ← chosen
- Upside: Strong relational model matches our domain perfectly
- Upside: ACID transactions satisfy compliance requirements natively
- Upside: Team has 10+ years of collective PostgreSQL experience
- Upside: Rich ecosystem for tooling, monitoring, migrations
- Downside: Vertical scaling has limits — we'll need read replicas or sharding if we 10x volume
- Downside: Operational burden is higher than DynamoDB (backups, parameter tuning, version upgrades) even with RDS managing the basics

**Option C: Amazon Aurora (PostgreSQL-compatible)**
- Upside: Better scalability than vanilla RDS PostgreSQL
- Upside: Faster failover, storage auto-scaling
- Downside: 2-3x the cost of standard RDS for our projected workload
- Downside: Some PostgreSQL extension compatibility gaps
- Downside: The scalability advantages don't matter at our current volume

### Deciding Factors

The core question was relational vs. non-relational. Our domain is inherently relational, our team knows SQL, and our compliance requirements demand strong consistency. DynamoDB would have required us to solve consistency at the application layer — extra complexity for a problem PostgreSQL solves natively.

We chose standard RDS over Aurora because our current scale doesn't justify the cost premium. If we grow past 200,000 orders/day, we'll revisit this (and Aurora is a drop-in migration path).

## Implications

**Benefits**:
- Straightforward data modeling that mirrors the business domain
- ACID compliance out of the box for audit and financial reporting
- Team can be productive immediately without a learning curve

**Trade-offs**:
- We accept a scaling ceiling. If order volume exceeds ~500K/day sustained, we'll need to revisit (read replicas first, then potentially Aurora or sharding)
- RDS requires more operational attention than DynamoDB — we're committing to managing connection pooling, query performance, and version upgrades

**Side effects**:
- This decision implies we'll use a SQL migration tool (we chose Prisma Migrate separately — see ADR-0004)
- Analytics queries can run against read replicas rather than requiring a separate data warehouse at our current scale

## See Also

- [ADR-0004: Prisma as ORM and migration tool](./0004-prisma-orm.md)
- [ADR-0007: Read replica for reporting queries](./0007-read-replica-reporting.md)
- Domain entities: `src/domain/entities/`
- Migration files: `src/infrastructure/migrations/`
