# API Documentation Guide

How to apply the shelf life framework to REST, GraphQL, authentication, and integration documentation.

## Contents

- [Long Shelf Life — Write Fully](#long-shelf-life--write-fully)
- [Medium Shelf Life — Write and Link](#medium-shelf-life--write-and-link)
- [Short Shelf Life — Breadcrumb Only](#short-shelf-life--breadcrumb-only)
- [What Belongs in Handwritten Docs](#what-belongs-in-handwritten-docs)
- [Recommended Doc Layout](#recommended-doc-layout)
- [Completeness Checklist](#completeness-checklist)

---

## Long Shelf Life — Write Fully

### When to Write a Decision Record

Write an ADR when:
- Selecting API style (REST vs. GraphQL vs. gRPC)
- Designing the authentication and authorization approach
- Defining a versioning strategy
- Setting rate limiting and throttling policies
- Choosing an error response format
- Selecting an API gateway approach

**Example titles**: ADR-0001: REST with OpenAPI for public-facing APIs, ADR-0002: OAuth 2.0 with managed identity provider, ADR-0003: URL-based versioning (/v1/, /v2/), ADR-0004: RFC 7807 Problem Details for error responses

### Conceptual Guide Content

Explain how to reason about the API surface:

```markdown
# API: How to Think About It

## Request Lifecycle

External requests pass through three layers:
1. **Gateway**: Handles rate limiting, token validation, and routing
2. **Application**: Business logic, request validation, response shaping
3. **Domain Services**: Core rules, invariants, and state management

## Authentication Flow

1. Client obtains a token from the identity provider
2. Token is sent in the `Authorization` header on every request
3. The gateway validates the token and extracts claims
4. Claims propagate into the application layer for authorization decisions

## Versioning Model

- Major versions appear in the URL path: `/api/v1/`, `/api/v2/`
- Non-breaking changes ship without a version bump
- Deprecated versions receive security patches for 12 months
- A new major version is required for any breaking contract change

See the OpenAPI spec at `/api-docs` for the current endpoint surface.
```

### Conventions Worth Documenting

- Resource naming: How endpoints and URL paths are structured
- Collection patterns: Pagination, filtering, sorting conventions
- Error envelope: Standard shape of error responses
- Idempotency: How clients should handle retries safely

---

## Medium Shelf Life — Write and Link

| Topic | What to Write | Where to Breadcrumb |
|---|---|---|
| Authentication setup | Conceptual flow and steps | Identity provider config |
| Rate limiting | Policy tiers and rationale | Gateway configuration |
| Common request patterns | Pagination and filtering approach | OpenAPI examples |

**Example:**

```markdown
## Integrating with the API

### Authentication

1. Register your application with the identity provider
2. Obtain client credentials (client ID + secret)
3. Request an access token from the token endpoint
4. Pass it as `Authorization: Bearer {token}` on each request

Tokens are valid for one hour. Refresh before expiry.

See the identity provider docs for detailed registration steps.
See `/api-docs` for per-endpoint authorization requirements.
```

---

## Short Shelf Life — Breadcrumb Only

| Don't Write Prose About | Breadcrumb To |
|---|---|
| List of endpoints | OpenAPI spec (`/api-docs`) |
| Request/response schemas | OpenAPI spec (generated from code) |
| Current rate limit thresholds | Gateway configuration |
| Auth provider endpoints | Identity provider well-known config |
| Per-endpoint status codes | OpenAPI spec |

**Breadcrumb phrasing:**

```markdown
# Durable
The API follows REST conventions and is fully described by its OpenAPI spec.
See `/api-docs` for every endpoint, its parameters, and example payloads.
For the machine-readable spec: `/api-docs/openapi.json`

# Fragile
## Endpoints

### GET /api/v1/orders
Returns a paginated list of orders.

**Query Parameters:**
| Name | Type | Required | Description |
| page | int | No | Page number |
...
```

---

## What Belongs in Handwritten Docs

### Integration Guide (Long Shelf Life)

Explain *how to integrate*, not *what endpoints exist*:

```markdown
# API Integration Guide

## Getting Started

1. Obtain credentials (see the access management docs)
2. Authenticate and retrieve a token
3. Test connectivity: `GET /api/v1/health`
4. Explore the full API at `/api-docs`

## Patterns

### Pagination
List endpoints accept `page` and `pageSize` query parameters.
Responses include `totalCount` and `hasNextPage` metadata.

### Filtering
Filter by field name in the query string: `?status=active`
Combine values with commas: `?status=active,pending`

### Error Handling
All errors use a standard envelope.
Always inspect the `status` and `detail` fields.

See the OpenAPI spec for endpoint-specific parameters and error codes.
```

### Error Reference (Medium Shelf Life)

Document error *categories* and how to react, not every possible error:

```markdown
## Error Categories

| HTTP Status | Meaning | What to Do |
|---|---|---|
| 400 | Invalid request | Fix based on the `errors` array |
| 401 | Not authenticated | Obtain or refresh your token |
| 403 | Not authorized | Verify your scopes and permissions |
| 404 | Resource not found | Confirm the resource ID or URL |
| 429 | Throttled | Wait for the duration in `Retry-After` |
| 500 | Server error | Retry with exponential backoff; escalate if it persists |

See the OpenAPI spec for endpoint-specific error details.
```

---

## Recommended Doc Layout

```
/docs/
├── decisions/
│   ├── 0001-rest-over-graphql.md
│   ├── 0002-auth-strategy.md
│   └── 0003-versioning-approach.md
├── guides/
│   ├── api-mental-model.md
│   └── api-integration.md            # For API consumers
└── conventions/
    └── api.md                        # Naming, patterns, error format

/src/api/
├── swagger/                          # Generated OpenAPI (source of truth)
└── README.md                         # Signpost to /docs/ and /api-docs
```

---

## Completeness Checklist

- [ ] ADRs cover API style, auth, and versioning decisions
- [ ] Integration guide exists for API consumers
- [ ] Error handling patterns are documented
- [ ] Authentication flow is explained conceptually
- [ ] No endpoint lists in prose (breadcrumb to OpenAPI)
- [ ] No schema definitions in prose (breadcrumb to OpenAPI)
- [ ] Rate limiting approach and tiers documented
- [ ] Postman collection or equivalent linked (if available)
