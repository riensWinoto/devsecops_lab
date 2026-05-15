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
| `iam_role` | IAM role with inline policy, instance profile, and EC2 trust policy |
| `secrets` | Secrets Manager secret with ephemeral password generation and KMS encryption |

### Encryption
Each environment provisions a dedicated KMS key used to encrypt all applicable resources. S3 buckets enforce server side encryption using the environment KMS key and deny any request not using HTTPS or unencrypted uploads via bucket policy. EC2 root volumes are encrypted using the same environment KMS key with 20GB gp3 configuration.

### Ephemeral Resources
The database password for `data-processor` is generated using an ephemeral resource and stored in Secrets Manager using a write-only attribute. The password is never persisted to Terraform state. The secret is encrypted with the environment KMS key.

The `data-processor` instance retrieves the secret at boot via user data and writes it to `/opt/app/db.env`. The `audit-server` has no secret requirement and does not receive a secret ARN.

### Identity & Access
Each EC2 instance is assigned a dedicated IAM role via an instance profile, following least privilege principles. Policy documents are rendered from template files and scoped to environment-specific resources only.

The `data-processor-role` is permitted to read from the raw data bucket, write to the processed data bucket, decrypt using the environment KMS key, and retrieve the database secret. Cross-environment S3 access is explicitly denied via a `NotResource` deny statement.

The `audit-server-role` is permitted to read from both buckets and decrypt using the environment KMS key. Write and delete operations are explicitly denied across all buckets.

The `platform-admin-policy` grants KMS key management and Secrets Manager administration permissions. Direct data access via `kms:Decrypt`, `s3:GetObject`, `s3:PutObject`, and `secretsmanager:GetSecretValue` is explicitly denied. The policy is attached to the `platform-admin` IAM user.

The KMS key policy enforces the access matrix at the key level, independently of IAM policies. The root account retains full key access to prevent lockout.

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