# StartTech Infrastructure

Infrastructure as Code (IaC) for the StartTech full-stack application using Terraform and AWS.

## Overview

This repository provisions the AWS infrastructure required to host the StartTech application, including networking, compute, storage, caching, monitoring, and security resources.

## Features

- VPC with public and private subnets
- Application Load Balancer (ALB)
- EC2 Auto Scaling Group with Launch Template
- ECR repository for backend images
- S3 + CloudFront for frontend hosting
- ElastiCache Redis for caching
- CloudWatch dashboard, alarms, and SNS notifications
- IAM roles and policies for EC2 and deployment automation


## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/Tbraima44/starttech-infra.git
cd starttech-infra
```

### 2. Configure Terraform variables

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform/terraform.tfvars` and set at least the following values:

```hcl
key_name    = "your-key"
mongodb_uri = "mongodb+srv://user:pass@cluster.mongodb.net"
alarm_email = "you@example.com"
```

### 3. Deploy the infrastructure

Use the provided deployment script:

```bash
./scripts/deploy-infrastructure.sh
```

You can also deploy manually:

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. View outputs

```bash
cd terraform
terraform output
```

## Project Structure

```
starttech-infra/
├── .github/
│   └── workflows/
│       └── infrastructure-deploy.yml    # Terraform deployment workflow
├── terraform/
│   ├── main.tf                          # Main Terraform configuration
│   ├── variables.tf                     # Input variables
│   ├── outputs.tf                       # Output values
│   ├── terraform.tfvars.example         # Example variables
│   └── modules/                         # Reusable modules
│       ├── networking/                  # VPC, subnets, security groups
│       ├── compute/                     # EC2, ASG, ECR, IAM
│       ├── storage/                     # S3, CloudFront
│       ├── load_balancer/               # ALB, target groups
│       ├── cache/                       # ElastiCache Redis
│       └── monitoring/                  # CloudWatch, SNS
├── scripts/
│   ├── deploy-infrastructure.sh         # Deployment script
│   ├── destroy-infrastructure.sh        # Destruction script
│   └── validate-terraform.sh            # Validation script
├── monitoring/
│   ├── cloudwatch-dashboard.json        # Dashboard configuration
│   ├── alarm-definitions.json           # Alarm definitions
│   └── log-insights-queries.txt         # Log queries
├── policies/
│   ├── deployment-policy.json           # IAM policy for deployment
│   └── ec2-assume-role.json             # EC2 assume role policy
└── README.md                            # This file
```

## Resources Created

| Resource | Service | Purpose |
| --- | --- | --- |
| VPC | AWS VPC | Network isolation |
| Public Subnets | AWS VPC | ALB and NAT gateway access |
| Private Subnets | AWS VPC | EC2, Redis, and private networking |
| Internet Gateway | AWS VPC | Public internet access |
| NAT Gateway | AWS VPC | Outbound access for private subnets |
| Application Load Balancer | AWS ALB | Traffic distribution |
| Auto Scaling Group | AWS EC2 | Backend scaling and availability |
| Launch Template | AWS EC2 | EC2 instance configuration |
| ECR Repository | AWS ECR | Backend image storage |
| S3 Bucket | AWS S3 | Frontend static hosting |
| CloudFront Distribution | AWS CloudFront | CDN delivery |
| ElastiCache Cluster | AWS ElastiCache | Redis caching |
| CloudWatch Dashboard | AWS CloudWatch | Monitoring dashboard |
| CloudWatch Alarms | AWS CloudWatch | Alerting |
| SNS Topic | AWS SNS | Email notifications |
| IAM Roles / Policies | AWS IAM | Access control |
| Security Groups | AWS EC2 | Network restrictions |

## Terraform Variables

### Required

| Variable | Description | Example |
| --- | --- | --- |
| `key_name` | SSH key pair name | `your-key` |
| `mongodb_uri` | MongoDB Atlas connection string | `mongodb+srv://user:pass@cluster.mongodb.net` |
| `alarm_email` | Email for CloudWatch alarms | `you@example.com` |

### Optional

| Variable | Default | Description |
| --- | --- | --- |
| `project_name` | `starttech` | Project name |
| `environment` | `production` | Deployment environment |
| `aws_region` | `us-east-1` | AWS region |
| `instance_type` | `t3.micro` | EC2 instance type |
| `asg_min_size` | `1` | Minimum ASG size |
| `asg_max_size` | `2` | Maximum ASG size |
| `asg_desired_capacity` | `1` | Desired ASG capacity |
| `domain_name` | `""` | Optional domain name |
| `certificate_arn` | `""` | Optional ACM certificate ARN |
| `redis_node_type` | `cache.t3.micro` | Redis node type |
| `redis_num_cache_nodes` | `1` | Redis node count |

## Outputs

| Output | Description |
| --- | --- |
| `s3_bucket_name` | Frontend S3 bucket name |
| `cloudfront_domain_name` | CloudFront distribution domain |
| `cloudfront_distribution_id` | CloudFront distribution ID |
| `ecr_repository_url` | ECR repository URL |
| `asg_name` | Auto Scaling Group name |
| `alb_dns_name` | Application Load Balancer DNS |
| `redis_endpoint` | ElastiCache Redis endpoint |
| `vpc_id` | VPC identifier |
| `frontend_url` | Public frontend URL |
| `backend_url` | Public backend URL |

## CI/CD Pipeline

The repository includes a GitHub Actions workflow for infrastructure automation.

### Workflow behavior

- **Pull request to `main`**: runs `terraform plan`
- **Push to `main`**: runs `terraform apply`
- **Manual trigger**: allows controlled destruction when needed

### Required GitHub Secrets

| Secret | Description |
| --- | --- |
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `MONGODB_URI` | MongoDB Atlas connection string |
| `SSH_KEY_NAME` | EC2 SSH key pair name |

## Monitoring

The deployment includes the following observability resources:

- CloudWatch dashboard for service health and performance
- CloudWatch alarms for high CPU and unhealthy targets
- SNS notifications sent to `alarm_email`
- CloudWatch Logs for backend and system log analysis

## Maintenance

### Scaling

Increase or decrease capacity by updating the ASG settings and reapplying Terraform:

```bash
cd terraform
terraform apply -var="asg_desired_capacity=5"
```

### Backend refresh

Trigger a rolling instance refresh for the ASG:

```bash
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name starttech-asg-production \
  --preferences '{"MinHealthyPercentage":90}' \
  --region us-east-1
```

### Destroy infrastructure

```bash
./scripts/destroy-infrastructure.sh
```

## Security

- Private subnets isolate backend infrastructure from direct public access
- Security groups restrict allowed traffic between services
- IAM roles follow least privilege principles
- Encryption is used for data in transit and at rest where applicable

## Validation

Run the repository validation script before committing changes:

```bash
./scripts/validate-terraform.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Run the validation script
5. Open a pull request

## Acknowledgments

- AWS
- HashiCorp Terraform
- AltSchool Africa

