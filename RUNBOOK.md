```markdown
# StartTech Infrastructure Runbook

This runbook documents how to deploy, maintain, troubleshoot, and safely destroy the AWS infrastructure provisioned by Terraform.

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Prerequisites](#prerequisites)
3. [Deploying Infrastructure](#deploying-infrastructure)
4. [Destroying Infrastructure](#destroying-infrastructure)
5. [Managing Terraform State](#managing-terraform-state)
6. [Scaling and Maintenance](#scaling-and-maintenance)
7. [Monitoring and Alerts](#monitoring-and-alerts)
8. [Troubleshooting](#troubleshooting)
9. [Security and Access](#security-and-access)
10. [Useful Commands](#useful-commands)

---

## Quick Reference

| Resource | How to Retrieve | Notes |
| --- | --- | --- |
| VPC ID | `terraform output vpc_id` | Network identifier |
| ALB DNS name | `terraform output alb_dns_name` | Public load balancer endpoint |
| CloudFront domain | `terraform output cloudfront_domain_name` | Frontend CDN endpoint |
| CloudFront distribution ID | `terraform output cloudfront_distribution_id` | Used for invalidations |
| S3 bucket name | `terraform output s3_bucket_name` | Frontend hosting bucket |
| ECR repository URL | `terraform output ecr_repository_url` | Backend image repository |
| Redis endpoint | `terraform output redis_endpoint` | Cache endpoint |
| ASG name | `terraform output asg_name` | Auto Scaling Group name |
| SSH key name | `terraform output` or `terraform.tfvars` | Defined in `key_name` |

> Replace the placeholder values in `terraform/terraform.tfvars` before deploying.

---

## Prerequisites

Before you begin, ensure the following are available:

- Terraform `>= 1.5.0`
- AWS CLI configured with credentials
- A valid MongoDB Atlas connection string
- Optional: a domain name and ACM certificate ARN for HTTPS
- Access to the GitHub repository and CI/CD secrets if using automation

### Required Terraform Variables

Create or update `terraform/terraform.tfvars` with at least:

```hcl
key_name    = "starttech-key"
mongodb_uri = "mongodb+srv://..."
alarm_email = "you@example.com"
```

Optional variables include:

- `project_name`
- `environment`
- `aws_region`
- `instance_type`
- `asg_min_size`
- `asg_max_size`
- `asg_desired_capacity`
- `domain_name`
- `certificate_arn`
- `redis_node_type`
- `redis_num_cache_nodes`

---

## Deploying Infrastructure

### Option 1: Use the deployment script (recommended)

Run the repository deployment script:

```bash
./scripts/deploy-infrastructure.sh
```

This script runs the following steps:

1. `terraform init`
2. `terraform validate`
3. `terraform plan -out=tfplan`
4. `terraform apply tfplan`

### Option 2: Deploy manually

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### Option 3: CI/CD deployment

1. Push changes to the `main` branch.
2. The GitHub Actions workflow deploys the infrastructure automatically.
3. Review the workflow logs for `terraform plan` and `terraform apply` output.

### Post-deployment checks

After the deployment completes, verify the outputs:

```bash
cd terraform
terraform output
```

Confirm that the following are populated:

- `alb_dns_name`
- `cloudfront_domain_name`
- `s3_bucket_name`
- `ecr_repository_url`
- `redis_endpoint`
- `asg_name`

---

## Destroying Infrastructure

> WARNING: This action permanently deletes AWS resources, including data.

### Recommended: use the destroy script

```bash
./scripts/destroy-infrastructure.sh
```

### Manual destroy

```bash
cd terraform
terraform destroy -auto-approve
```

### Destroy a single module only

If you need to remove only one part of the stack, use a target:

```bash
cd terraform
terraform destroy -target=module.compute -auto-approve
```

---

## Managing Terraform State

Terraform state is stored remotely with a backend. If a deployment fails, the state lock may remain and block future runs.

### Verify the backend configuration

Check the Terraform backend settings in `terraform/main.tf` before making changes.

### Release a stale lock

If a lock remains, remove it from DynamoDB:

```bash
aws dynamodb delete-item \
  --table-name terraform-locks \
  --key '{"LockID": {"S": "starttech-terraform-state/terraform.tfstate"}}' \
  --region us-east-1
```

### Use `-lock=false` only when safe

This is only appropriate if you are certain no other deployment is in progress.

---

## Scaling and Maintenance

### Change the Auto Scaling Group capacity

```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name <asg-name> \
  --desired-capacity 3 \
  --region us-east-1
```

### Update the instance type

1. Update `instance_type` in `terraform/terraform.tfvars`.
2. Re-apply Terraform.
3. Confirm the ASG launches instances with the new type.

### Trigger an instance refresh

```bash
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name <asg-name> \
  --preferences '{"MinHealthyPercentage":90}' \
  --region us-east-1
```

### Update backend image tag

If the backend image needs to be refreshed, update `backend_image_tag` and re-apply Terraform.

---

## Monitoring and Alerts

### CloudWatch dashboard

- Dashboard configuration is located in `monitoring/cloudwatch-dashboard.json`
- Use the AWS Console to review CPU, request count, and log-based widgets

### CloudWatch alarms

Alarm definitions are stored in `monitoring/alarm-definitions.json`.

Typical alarms include:

- High CPU usage
- Unhealthy targets behind the ALB
- Alarm notifications sent to `alarm_email`

### CloudWatch Logs

Use CloudWatch Logs Insights to inspect application and system logs for errors, latency, and deployment issues.

---

## Troubleshooting

### 1. Instances are repeatedly launching and terminating

Check the ASG activity history:

```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <asg-name> \
  --region us-east-1
```

Common causes:

- Invalid or missing SSH key pair
- Unsupported instance type in the selected region
- Errors in the user data script

Inspect the launch template user data:

```bash
aws ec2 describe-launch-template-versions \
  --launch-template-name <launch-template-name> \
  --region us-east-1 \
  --query "LaunchTemplateVersions[0].LaunchTemplateData.UserData" \
  --output text | base64 -d
```

### 2. Backend returns `502 Bad Gateway`

Check target health:

```bash
aws elbv2 describe-target-health \
  --target-group-arn $(aws elbv2 describe-target-groups \
    --names <target-group-name> \
    --region us-east-1 \
    --query "TargetGroups[0].TargetGroupArn" \
    --output text) \
  --region us-east-1
```

If targets are unhealthy:

1. Connect to the instance using SSH or SSM.
2. Review container status.
3. Inspect backend logs.

```bash
 docker ps -a
docker logs backend
```

Common causes:

- MongoDB connection failure
- Redis endpoint or connectivity issue
- Missing environment variables

### 3. MongoDB Atlas connection errors

- Confirm the Atlas IP allowlist includes the deployment network path.
- Verify `mongodb_uri` is present and valid in `terraform/terraform.tfvars`.

### 4. Redis errors

- Verify the Redis endpoint from `terraform output redis_endpoint`
- Confirm the backend security group allows inbound traffic on port `6379`

---

## Security and Access

### IAM roles and policies

- EC2 instance role grants access for CloudWatch Logs, ECR pull, and SSM
- Deployment policy is stored in `policies/deployment-policy.json`

### SSH access

Use the configured key name from `key_name`:

```bash
ssh -i <private-key>.pem ec2-user@<public-ip>
```

For private instances without a public IP:

```bash
aws ssm start-session --target <instance-id> --region us-east-1
```

### S3 bucket access

The frontend bucket is configured for static website hosting. Review bucket policies before making public access changes.

---

## Useful Commands

### Validate Terraform configuration

```bash
cd terraform
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

### View all outputs

```bash
cd terraform
terraform output
```

### View all resources in current state

```bash
cd terraform
terraform state list
```

### Check current Terraform plan without applying

```bash
cd terraform
terraform plan
```

---

## Notes

- Use the repository scripts for repeatable deployments and destruction.
- Keep `terraform/terraform.tfvars` local and out of source control.
- Update monitoring and alarm settings before making major infrastructure changes.


