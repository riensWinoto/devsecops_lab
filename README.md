# devsecops_lab
End-to-end DevSecOps lab covering infrastructure as code, security gates, and application deployment using MiniStack as the local AWS emulator.

---

## Prerequisites
- Docker
- Terraform
- AWS CLI

---

## Setup

### Environment Variables
`.env.example` contains all required variables with placeholder values. Values should be updated to match the target environment before running any commands.

```bash
cp .env.example .env
```

The `.env` file must be sourced before running Terraform commands:
```bash
source .env
```

### AWS CLI
The following alias is used to interact with MiniStack using the AWS CLI:
```bash
alias minstack='docker run --network devsecops_lab_ministack -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test -e AWS_REGION=ap-southeast-2 --rm -it amazon/aws-cli --endpoint-url=http://ministack:4566'
```

> **Note:** MiniStack must be running before the alias can be used.

Example usage:
```bash
minstack s3 ls
minstack s3 ls s3://devsecops-lab/
```

### MiniStack
MiniStack is started using Docker Compose:
```bash
docker compose up -d
```

Once MiniStack is running, the state bucket must be created before initializing Terraform:
```bash
minstack s3 mb s3://devsecops-lab
```

### Terraform
Each environment must be initialized separately:
```bash
cd terraform/environments/dev && terraform init
cd terraform/environments/staging && terraform init
```

---

## Infrastructure

### Resources
Each environment provisions the following resources:

| Resource | Name | Description |
|---|---|---|
| S3 Bucket | `<environment>-raw-data-<account_id>` | Ingestion of raw financial data |
| S3 Bucket | `<environment>-processed-data-<account_id>` | Storage of processed financial data |
| EC2 Instance | `<environment>-data-processor` | Reads raw data, writes processed data |
| EC2 Instance | `<environment>-audit-server` | Read-only access to both buckets for auditing |
| IAM User | `<environment>-platform-admin` | Platform administration — no direct data access |

### Usage
Provision an environment:
```bash
cd terraform/environments/<environment>
terraform apply
```

Destroy an environment:
```bash
cd terraform/environments/<environment>
terraform destroy
```

Both environments are independent and can be provisioned or destroyed separately.