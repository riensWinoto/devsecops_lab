# devsecops_lab
End-to-end DevSecOps lab covering infrastructure as code, security gates, and application deployment using MiniStack as the local AWS emulator.

---

## Architecture Overview

![Architecture](docs/terraform-architecture.png)

---

## Repository Structure

```
terraform/
├── environments
│   ├── dev                   # dev environment — independent state and config
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── variables.tf
│   └── staging               # staging environment — independent state and config
│       ├── backend.tf
│       ├── main.tf
│       ├── terraform.tfvars
│       └── variables.tf
├── modules
│   ├── ec2                   # EC2 instance with encrypted volume and instance profile
│   ├── iam                   # IAM user with environment-scoped naming
│   ├── iam_role              # IAM role with instance profile and EC2 trust policy
│   ├── kms                   # KMS key with rotation and environment alias
│   ├── s3                    # S3 bucket with versioning, SSE, and bucket policy
│   └── secrets               # Secrets Manager secret with ephemeral password
└── policies
    ├── audit-server-role.json.tpl
    ├── data-processor-role.json.tpl
    ├── kms-key.json.tpl
    └── platform-admin-user.json.tpl
```

Each environment directory is self-contained with its own backend, variables, and state. Modules are environment-agnostic and accept an `environment` variable to scope all resource names and tags. Policy documents live in `terraform/policies/` as template files rendered at apply time via `templatefile()`.

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
| KMS Key | `alias/<environment>-data-platform` | Encryption key for all environment resources |
| S3 Bucket | `<environment>-raw-data-<account_id>` | Ingestion of raw financial data |
| S3 Bucket | `<environment>-processed-data-<account_id>` | Storage of processed financial data |
| EC2 Instance | `<environment>-data-processor` | Reads raw data and writes processed data |
| EC2 Instance | `<environment>-audit-server` | Read-only access to both buckets for auditing |
| IAM User | `<environment>-platform-admin` | Platform administration with no direct data access |
| IAM Role | `<environment>-data-processor-role` | Least privilege role for data-processor instance |
| IAM Role | `<environment>-audit-server-role` | Read-only role for audit-server instance |
| IAM Policy | `<environment>-platform-admin-policy` | Admin policy with explicit data access denials |
| Secrets Manager Secret | `<environment>-data-processor-db-password` | Database password for data-processor, encrypted with environment KMS key |

### Modules
Resources are provisioned through reusable modules located under `terraform/modules/`:

| Module | Description |
|---|---|
| `kms` | KMS key with rotation enabled and environment-scoped alias |
| `s3` | S3 bucket with versioning, server side encryption, and bucket policy enforcement |
| `ec2` | EC2 instance with encrypted root volume, optional secret retrieval on boot, and instance profile attachment |
| `iam` | IAM user with environment-scoped naming |
| `iam_role` | IAM role with inline permission policy, instance profile, and EC2 trust policy |
| `secrets` | Secrets Manager secret with ephemeral password generation and KMS encryption |

### Encryption
Each environment provisions a dedicated KMS key used to encrypt all applicable resources. S3 buckets enforce server side encryption using the environment KMS key and deny any request not using HTTPS or unencrypted uploads via bucket policy. EC2 root volumes are encrypted using the same environment KMS key with 20GB gp3 configuration. KMS key rotation is enabled with a 365-day rotation period.

State files are stored in S3 with `encrypt = true` configured on the backend. On real AWS this enforces SSE at rest via the S3 backend.

### Ephemeral Resources
The database password for `data-processor` is generated using an ephemeral `random_password` resource and stored in Secrets Manager using a write-only attribute (`secret_string_wo`). The password is never written to Terraform state. The secret is encrypted with the environment KMS key.

The `data-processor` instance retrieves the secret at boot via user data and writes it to `/opt/app/db.env` with `600` permissions. The `audit-server` has no secret requirement and does not receive a secret ARN.

Using an ephemeral resource over a standard `random_password` ensures the plaintext password never appears in state, removing a common credential exposure vector in infrastructure-as-code pipelines.

### Identity & Access

Each EC2 instance is assigned a dedicated IAM role via an instance profile. Policy documents are rendered from `templatefile()` at apply time and scoped to environment-specific resource ARNs only.

| Principal | s3:GetObject raw | s3:PutObject processed | s3:GetObject processed | kms:Decrypt | kms:Manage | secretsmanager:GetSecretValue |
|---|---|---|---|---|---|---|
| `data-processor-role` | ✓ | ✓ | ✗ | ✓ | ✗ | ✓ |
| `audit-server-role` | ✓ | ✗ explicit deny | ✓ | ✓ | ✗ | ✗ |
| `platform-admin` | ✗ explicit deny | ✗ explicit deny | ✗ explicit deny | ✗ explicit deny | ✓ | ✗ explicit deny |

The KMS key policy enforces the access matrix at the key level independently of IAM policies, providing defense in depth. The root account retains full key access to prevent lockout.

Cross-environment S3 access is explicitly denied on `data-processor-role` via a `NotResource` deny statement covering all granted S3 actions.

### Environment Separation
Directory-based environment separation is used instead of Terraform workspaces. Each environment has its own backend configuration, variable definitions, and state file to ensure strict isolation and prevent accidental cross-environment operations.

Workspaces are not suitable for this use case as they share a backend configuration and do not provide true environment isolation.

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