# OpenClaw - Claude Code Context

## Project

Terraform infrastructure provisioning a scheduled EC2 instance on AWS. The instance runs during Colombian business hours (6 AM - 6 PM America/Bogota) to optimize costs.

## Tech Stack

- Terraform (>= 1.5.0) with AWS provider (~> 5.0)
- AWS: EC2, EventBridge Scheduler, IAM, VPC
- GitHub Actions with OIDC authentication
- Remote state in S3 (`beitlab-terraform-state`)

## File Structure

| File | Purpose |
|---|---|
| `main.tf` | EC2 instance, security group, AMI data source, VPC data source |
| `scheduler.tf` | EventBridge schedules (start/stop), IAM role for scheduler |
| `variables.tf` | Input variables (project_name, instance_type, key_name, ami_id) |
| `outputs.tf` | Outputs (instance_id, public_ip, schedule info) |
| `provider.tf` | AWS provider config, default tags (Project, ManagedBy) |
| `backend.tf` | S3 backend and required provider versions |
| `iam-github-policy.json` | IAM policy for GitHub Actions OIDC role |
| `.github/workflows/terraform.yml` | CI/CD pipeline |

## Conventions

- All resources tagged with `Project` and `ManagedBy` via provider default tags
- Resource names prefixed with `var.project_name` (default: `"openclaw"`)
- Region: `us-east-1`

## Validation Commands

```bash
terraform fmt -check    # Check formatting
terraform validate      # Validate configuration
terraform plan          # Preview changes
```

## CI/CD

Push to `main` triggers auto-apply. PRs get a plan comment. Authentication is OIDC-based (no static keys). Terraform operations are serialized via concurrency group.
