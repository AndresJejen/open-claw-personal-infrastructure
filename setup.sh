#!/usr/bin/env bash
set -euo pipefail

GITHUB_REPO="AndresJejen/open-claw-personal-infrastructure"
BUCKET_NAME="beitlab-terraform-state"
ROLE_NAME="openclaw-github-actions"
KEY_NAME="openclaw"
REGION="us-east-1"
SSH_DIR="$HOME/.ssh"

echo "==> Getting AWS account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "    Account: $ACCOUNT_ID"

# Step 1: S3 state bucket
echo "==> Creating S3 state bucket..."
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" 2>/dev/null || echo "    Bucket already exists, skipping."

aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled
echo "    Versioning enabled."

# Step 2: GitHub OIDC provider
echo "==> Creating GitHub OIDC provider..."
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 2>/dev/null \
  || echo "    OIDC provider already exists, skipping."

# Step 3: IAM role for GitHub Actions
echo "==> Creating IAM role: $ROLE_NAME..."
TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF
)

aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document "$TRUST_POLICY" 2>/dev/null \
  || echo "    Role already exists, skipping."

# Step 4: Attach permissions policy
echo "==> Attaching permissions policy..."
aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name openclaw-terraform \
  --policy-document file://iam-github-policy.json

# Step 5: Set GitHub Actions secret
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query Role.Arn --output text)
echo "==> Role ARN: $ROLE_ARN"

if command -v gh &>/dev/null; then
  echo "==> Setting GitHub Actions secret..."
  gh secret set AWS_ROLE_ARN --repo "$GITHUB_REPO" --body "$ROLE_ARN"
  echo "    Secret set."
else
  echo "==> gh CLI not found. Set this secret manually in GitHub:"
  echo "    Settings > Secrets > Actions > AWS_ROLE_ARN = $ROLE_ARN"
fi

# Step 6: Create EC2 key pair
echo "==> Creating EC2 key pair: $KEY_NAME..."
mkdir -p "$SSH_DIR"
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &>/dev/null; then
  echo "    Key pair already exists, skipping."
else
  aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --region "$REGION" \
    --query 'KeyMaterial' \
    --output text > "$SSH_DIR/$KEY_NAME.pem"
  chmod 400 "$SSH_DIR/$KEY_NAME.pem"
  echo "    Key saved to $SSH_DIR/$KEY_NAME.pem"
fi

# Verify
echo "==> Running terraform init..."
terraform init

echo "==> Running terraform plan..."
terraform plan -var="key_name=$KEY_NAME"

echo "==> Setup complete."
