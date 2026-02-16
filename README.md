# OpenClaw

AWS infrastructure for a cost-optimized EC2 instance with automatic start/stop scheduling during Colombian business hours.

## Architecture

- **EC2 Instance** (`t4g.medium` ARM64) with Amazon Linux 2023 and 20GB gp3 root volume
- **EventBridge Scheduler** starts the instance at 6:00 AM and stops it at 6:00 PM (America/Bogota)
- **Security Group** allows SSH (port 22) inbound and all outbound traffic
- **IAM Role** scoped to only start/stop the specific instance

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- S3 bucket `beitlab-terraform-state` for remote state
- (Optional) An EC2 key pair for SSH access

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Variables

| Variable | Description | Default |
|---|---|---|
| `project_name` | Resource naming and tagging | `"openclaw"` |
| `instance_type` | EC2 instance type | `"t4g.medium"` |
| `key_name` | SSH key pair name (empty to disable) | `""` |
| `ami_id` | Custom AMI ID (empty for latest Amazon Linux 2023 ARM64) | `""` |

## Outputs

| Output | Description |
|---|---|
| `instance_id` | EC2 instance ID |
| `public_ip` | Public IP address |
| `schedule_start` | Start schedule info |
| `schedule_stop` | Stop schedule info |

## CI/CD

The GitHub Actions workflow (`.github/workflows/terraform.yml`) runs on pushes and PRs to `main`:

1. Format check and validation
2. Plan (commented on PRs)
3. Auto-apply on merge to `main`

Authentication uses OIDC via `secrets.AWS_ROLE_ARN`.

## Security Note

SSH (port 22) is open to `0.0.0.0/0`. Consider restricting the CIDR block to known IPs for production use.
