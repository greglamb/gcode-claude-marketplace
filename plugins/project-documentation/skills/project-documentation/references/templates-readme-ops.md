# README Templates: Infrastructure, Deployment, and Serverless

Copy-paste README templates for infrastructure modules, container services, serverless functions, and CI/CD pipelines.

For application and library READMEs, see [templates-readme-apps.md](templates-readme-apps.md).

## Contents

- [Container Image](#container-image)
- [Terraform Module (AWS)](#terraform-module-aws)
- [Terraform Module (GCP)](#terraform-module-gcp)
- [CI/CD Pipeline (GitHub Actions)](#cicd-pipeline-github-actions)
- [Serverless Functions (AWS Lambda)](#serverless-functions-aws-lambda)
- [Container Service (AWS ECS Fargate)](#container-service-aws-ecs-fargate)
- [Message Queue Integration (SQS/SNS)](#message-queue-integration-sqssns)

---

## Container Image

```markdown
# Image Name

> One sentence: what runs inside this container.

## 🚀 Quick Start

```bash
docker pull org/image:latest
docker run -p 8080:8080 org/image:latest
```

Confirm at http://localhost:8080.

## 🎯 What It Does

- [Primary purpose]
- [What's bundled]

## ⚙️ Configuration

| Variable | Required | Purpose |
|----------|----------|---------|
| `PORT` | No | Listener port (default: 8080) |

See [`docker-compose.yml`](./docker-compose.yml) for the full configuration surface.

## 🧑‍💻 Building

```bash
docker build -t image-name .
```
```

---

## Terraform Module (AWS)

```markdown
# module-name

> One sentence: what AWS resources this provisions.

[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.5-blue)]()
[![AWS Provider](https://img.shields.io/badge/aws-%3E%3D5.0-orange)]()

## 🚀 Quick Start

```hcl
module "example" {
  source = "github.com/org/repo//modules/module-name"

  region = "us-east-1"
  name   = "my-resource"
  tags   = { Environment = "dev" }
}
```

```bash
terraform init
terraform plan
terraform apply
```

## 🎯 What It Creates

- [Primary resource]
- [Supporting resources]

## 📚 Docs

- [Inputs](./docs/inputs.md)
- [Outputs](./docs/outputs.md)
- [Examples](./examples/)
```

---

## Terraform Module (GCP)

```markdown
# module-name

> One sentence: what GCP resources this provisions.

[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.5-blue)]()

## 🚀 Quick Start

```hcl
module "example" {
  source = "github.com/org/repo//modules/module-name"

  project_id = "my-gcp-project"
  region     = "us-central1"
  name       = "my-resource"
}
```

```bash
terraform init
terraform plan
terraform apply
```

## 🎯 What It Creates

- [Primary resource]
- [Supporting resources]

## 📚 Docs

- [Inputs](./docs/inputs.md)
- [Outputs](./docs/outputs.md)
- [Examples](./examples/)
```

---

## CI/CD Pipeline (GitHub Actions)

```markdown
# Workflow Name

> One sentence: what this workflow does and what triggers it.

## 🎯 What It Does

- [Primary job or outcome]
- Triggers: [push / PR / schedule / dispatch]

## 🚀 Usage

Copy `.github/workflows/workflow.yml` into your repo.

**Secrets needed**:
- `SECRET_NAME` — [What it's for]

**Variables needed**:
- `VAR_NAME` — [What it controls]

## ⚙️ Configuration

See the workflow file for all inputs and toggles.
```

---

## Serverless Functions (AWS Lambda)

```markdown
# Function Name

> One sentence: what these functions do.

[![Lambda](https://img.shields.io/badge/AWS%20Lambda-Node.js%2020-orange)]()
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue)]()

## 🚀 Quick Start

```bash
git clone https://github.com/org/repo.git
cd repo
npm install
npm run build
npx sls invoke local -f functionName
```

With serverless-offline: http://localhost:3000/dev/functionName

## 🎯 What It Does

- [HTTP-triggered function purpose]
- [Scheduled function purpose]
- [Queue-triggered function purpose]

## 🧑‍💻 Deploy

```bash
npx sls deploy --stage dev
```

## 📚 Docs

- [Local Dev](./docs/runbooks/local-dev.md)
- [Configuration](./docs/guides/configuration.md)
- [Deployment](./docs/runbooks/deployment.md)
```

---

## Container Service (AWS ECS Fargate)

```markdown
# Application Name

> One sentence: what this application does.

[![ECS Fargate](https://img.shields.io/badge/AWS-ECS%20Fargate-orange)]()
[![CI](https://img.shields.io/github/actions/workflow/status/org/repo/ci.yml)]()

## 🚀 Quick Start

**Locally:**

```bash
git clone https://github.com/org/repo.git
cd repo
npm install
npm run dev
```

Visit http://localhost:3000.

**Deploy:**

```bash
aws ecs update-service --cluster CLUSTER --service SERVICE --force-new-deployment
```

## 🎯 What It Does

- [Primary capability]
- [Secondary capability]

## ⚙️ Configuration

Settings come from AWS SSM Parameter Store or environment variables.

| Setting | Purpose |
|---------|---------|
| `DATABASE_URL` | Primary data store |
| `FEATURE_X_ENABLED` | [Toggle description] |

See [`.env.example`](./.env.example) for the full list.

## 🧑‍💻 Build & Push

```bash
docker build -t APP_NAME .
aws ecr get-login-password | docker login --username AWS --password-stdin ECR_URI
docker push ECR_URI/APP_NAME:latest
```

Or let CI handle it — see `.github/workflows/deploy.yml`.

## 📚 Docs

- [Architecture](./docs/guides/architecture.md)
- [Deployment](./docs/runbooks/deployment.md)
- [Scaling](./docs/how-to/scaling.md)
```

---

## Message Queue Integration (SQS/SNS)

```markdown
# Integration Name

> One sentence: what messaging this handles.

[![AWS](https://img.shields.io/badge/AWS-SQS%20%2F%20SNS-orange)]()
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-blue)]()

## 🚀 Quick Start

```bash
git clone https://github.com/org/repo.git
cd repo
npm install
npm run dev
```

## 🎯 What It Does

- [Primary messaging use case]
- [Queue vs topic usage]
- [What systems connect]

## 🧱 Message Flow

```
[Producer] → SQS Queue / SNS Topic → [Consumer / Subscriber]
```

See [Architecture](./docs/guides/architecture.md) for detailed flow diagrams.

## ⚙️ Configuration

| Setting | Purpose |
|---------|---------|
| `AWS_REGION` | Target region |
| `SQS_QUEUE_URL` | Queue endpoint |
| `SNS_TOPIC_ARN` | Topic ARN (for pub/sub) |

## 📨 Message Contracts

Schemas live in `src/contracts/`. See that module for the current message types.

## 🧑‍💻 Local Testing

```bash
npx ts-node src/publisher/index.ts   # Send a test message
npx ts-node src/consumer/index.ts    # Start consuming
```

## 📚 Docs

- [Architecture](./docs/guides/architecture.md) — Flow and design rationale
- [Contracts](./src/contracts/) — Current message schemas
- [Error Handling](./docs/how-to/error-handling.md) — DLQ and retry patterns
- [Monitoring](./docs/how-to/monitoring.md) — Metrics and alerts
```
