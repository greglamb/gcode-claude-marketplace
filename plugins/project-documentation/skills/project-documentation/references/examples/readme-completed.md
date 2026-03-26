# Example: Completed README

This is what a finished README looks like — a signpost, not a textbook. Notice what's *not* here: no architecture deep-dive, no endpoint inventory, no configuration reference. It gets you oriented and running, then sends you to the real docs.

---

# OrderFlow

> Automated order processing pipeline for wholesale distribution, reducing manual processing time from 4 hours to 15 minutes per batch.

[![CI](https://img.shields.io/github/actions/workflow/status/acme-corp/orderflow/ci.yml?branch=main)]()
[![TypeScript](https://img.shields.io/badge/TypeScript-5.4-blue)]()

## 🚀 Quick Start

```bash
git clone https://github.com/acme-corp/orderflow.git
cd orderflow
cp .env.example .env
docker compose up -d
npm install
npm run dev
```

Open http://localhost:3000/api-docs to see the Swagger UI. You should see the OrderFlow API documentation page.

## 🎯 What It Does

- Ingests orders from EDI feeds, CSV uploads, and partner APIs
- Validates orders against inventory and pricing rules
- Routes orders through configurable approval workflows
- Publishes confirmed orders to the fulfillment pipeline
- Provides real-time dashboards for operations teams

## 🧑‍💻 Example

Submit a test order:

```bash
curl -X POST http://localhost:3000/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{"customerId": "ACME-001", "items": [{"sku": "WDG-100", "quantity": 50}]}'
```

You should receive a `201 Created` response with an order ID.

## 📚 Docs

| Looking for... | Go to... |
|---|---|
| How the system works | [Developer Guide](./docs/guides/codebase.md) |
| Data model and flow | [Data Architecture](./docs/guides/data-architecture.md) |
| Add a feature | [How-To Guides](./docs/how-to/) |
| Why we chose X | [Decisions](./docs/decisions/) |
| Deploy to staging/prod | [Deployment Runbook](./docs/runbooks/deployment.md) |
| Config options | [`.env.example`](./.env.example) |
| API endpoints | [Swagger UI](http://localhost:3000/api-docs) (auto-generated) |

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for setup details and conventions.

## 🛡 Security

See [SECURITY.md](./SECURITY.md) to report vulnerabilities.

## 📄 License

Proprietary — Acme Corp. See [LICENSE](./LICENSE).
