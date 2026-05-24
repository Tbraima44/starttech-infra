```markdown
# StartTech Infrastructure Runbook

This runbook covers the management and maintenance of the AWS infrastructure provisioned by Terraform.

## Table of Contents
- [Quick Reference](#quick-reference)
- [Deploying Infrastructure Changes](#deploying-infrastructure-changes)
- [Destroying the Infrastructure](#destroying-the-infrastructure)
- [Managing State Lock](#managing-state-lock)
- [Scaling the Application](#scaling-the-application)
- [Monitoring & Alarms](#monitoring--alarms)
- [Troubleshooting](#troubleshooting)
- [Security & Access](#security--access)

---

## Quick Reference

| Resource | Identifier |
|----------|------------|
| **VPC ID** |  |
| **ALB DNS** |  |
| **CloudFront Domain** |  |
| **CloudFront Distribution ID** |  |
| **S3 Bucket** |  |
| **ECR Repository** |  |
| **Redis Endpoint** |  |
| **ASG Name** |  |
| **SSH Key Pair** |  |

---

## Deploying Infrastructure Changes

### Using CI/CD (Recommended)
1. Push changes to the `main` branch of `starttech-infra`.
2. The GitHub Actions workflow (`infrastructure-deploy.yml`) will automatically run `terraform plan` and `terraform apply`.
3. Verify the output in the Actions console.

### Manual Deployment from Local
```bash
cd terraform
terraform init
terraform plan \
  -var="mongodb_uri=<your-mongodb-uri>" \
  -var="key_name=starttech-key" \
  -var="certificate_arn=" \
  -var="domain_name=" \
  -var="alarm_email=yours@email.com" \
  -out=tfplan
terraform apply tfplan
```

Important: The terraform.tfvars file contains sensitive values and is not committed to Git. Use the above -var flags or a local terraform.tfvars file.

---

Destroying the Infrastructure

WARNING: This will permanently delete all AWS resources, including data.

```bash
cd terraform
terraform destroy \
  -var="mongodb_uri=<your-mongodb-uri>" \
  -var="key_name=your-key" \
  -auto-approve
```

If you only need to destroy a specific module (e.g., compute), use:

```bash
terraform destroy -target=module.compute -auto-approve
```

---

Managing State Lock

Terraform state is stored in an S3 bucket (starttech-terraform-state) with a DynamoDB lock table (terraform-locks). If a plan or apply fails, the lock might remain.

Forcefully Release a Lock

```bash
aws dynamodb delete-item \
    --table-name terraform-locks \
    --key '{"LockID": {"S": "starttech-terraform-state/terraform.tfstate"}}' \
    --region us-east-1
```

Alternatively, use -lock=false in the Terraform command, but only if you are certain no other process is running.

---

Scaling the Application

Change the number of EC2 instances

```bash
# Set desired capacity (min: 1, max: 10)
aws autoscaling set-desired-capacity \
    --auto-scaling-group-name starttech-asg-production \
    --desired-capacity 3 \
    --region us-east-1
```

Modify instance type

Update the instance_type variable in terraform.tfvars or the workflow, then re‑apply Terraform. The ASG will perform a rolling update automatically.

---

Monitoring & Alarms

CloudWatch Dashboard

· Name: starttech-production
· Contents: CPU utilization, ALB request count, and a Logs Insights widget for top errors.
· Access via AWS Console → CloudWatch → Dashboards.

Alarms

· High CPU Alarm: Triggers if average CPU > 80% for 2 evaluation periods.
· Unhealthy Hosts Alarm: Triggers if any target in the ALB target group is unhealthy.
· Alarms send email to the configured alarm_email.

Logs

· Log group: /aws/ec2/starttech-backend-production
· Use Logs Insights to query errors, response times, etc.

---

Troubleshooting

Instances are cycling (launching and terminating)

1. Check ASG activity history:
   ```bash
   aws autoscaling describe-scaling-activities \
       --auto-scaling-group-name starttech-asg-production \
       --region us-east-1
   ```
2. Common causes:
   · Invalid key pair – ensure the key pair exists.
   · Instance type not available – switch to t2.micro or t3.micro.
   · User‑data script errors – check the launch template.
3. Inspect the user‑data script:
   ```bash
   aws ec2 describe-launch-template-versions \
       --launch-template-name starttech-backend-production \
       --region us-east-1 \
       --query "LaunchTemplateVersions[0].LaunchTemplateData.UserData" \
       --output text | base64 -d
   ```

Backend returns 502 Bad Gateway

1. Verify the ALB target health:
   ```bash
   aws elbv2 describe-target-health \
       --target-group-arn $(aws elbv2 describe-target-groups \
           --names starttech-tg-production \
           --region us-east-1 \
           --query "TargetGroups[0].TargetGroupArn" \
           --output text) \
       --region us-east-1
   ```
2. If targets are unhealthy, SSH (or use SSM) into an instance and check the Docker container:
   ```bash
   docker ps -a
   docker logs backend
   ```
3. Common issues: MongoDB connection string, Redis endpoint, or missing environment variables.

MongoDB Atlas connection error

· Ensure the MongoDB Atlas IP whitelist includes 0.0.0.0/0 (or the NAT Gateway’s Elastic IP).
· Verify the MONGO_URI environment variable is correctly set in the EC2 launch template.

Redis connection error

· Verify the Redis endpoint is master.starttech-redis-production.xsbsfs.use1.cache.amazonaws.com and port 6379.
· Ensure the security group allows inbound traffic on port 6379 from the backend instances.

---

Security & Access

IAM Roles

· EC2 Role: starttech-ec2-role-production – grants CloudWatch logs, ECR pull, and SSM access.
· Deployment Policy: deployment-policy.json – used by GitHub Actions workflows.

SSH Access

· The key pair starttech-key is required. Private key was generated during setup.
· Connect: ssh -i starttech-key.pem ec2-user@<public-ip>
· For private instances without public IP, use SSM:
  ```bash
  aws ssm start-session --target <instance-id> --region us-east-1
  ```

S3 Bucket Policy

· The frontend bucket is publicly readable for static website hosting.
· Block Public Access has been disabled at the bucket level; account‑level settings were also adjusted.

---

Additional Resources

· Terraform Documentation
· AWS CLI Command Reference


