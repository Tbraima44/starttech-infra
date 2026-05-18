Infrastructure as Code (IaC) for the StartTech full-stack application using Terraform.

## 🏗️ Architecture

```

┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                           │
│  Region: us-east-1                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │                     VPC (10.0.0.0/16)                 │ │
│  │                                                       │ │
│  │  ┌─────────────────┐  ┌──────────────────────────┐  │ │
│  │  │  Public Subnets  │  │    Private Subnets        │  │ │
│  │  │                 │  │                           │  │ │
│  │  │  ┌────────────┐ │  │  ┌────────────────────┐  │  │ │
│  │  │  │    ALB     │ │  │  │   EC2 Auto Scaling │  │  │ │
│  │  │  │ (HTTP/HTTPS)│ │  │  │       Group        │  │  │ │
│  │  │  └─────┬──────┘ │  │  └─────────┬──────────┘  │  │ │
│  │  │        │        │  │            │              │  │ │
│  │  └────────┼────────┘  └────────────┼──────────────┘  │ │
│  │           │                       │                  │ │
│  │  ┌────────┼───────────────────────┼──────────────┐  │ │
│  │  │        │        NAT Gateway     │              │  │ │
│  │  └────────┼───────────────────────┼──────────────┘  │ │
│  │           │                       │                  │ │
│  │  ┌────────▼────────┐  ┌───────────▼───────────┐    │ │
│  │  │ Internet Gateway│  │  ElastiCache Redis    │    │ │
│  │  └─────────────────┘  └───────────────────────┘    │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │               External Services                       │ │
│  │  ┌─────────────────┐  ┌──────────────────────────┐  │ │
│  │  │  S3 + CloudFront│  │     MongoDB Atlas         │  │ │
│  │  │   (Frontend)    │  │     (Database)            │  │ │
│  │  └─────────────────┘  └──────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

```

## 📦 Resources Created

| Resource              | Service                          | Purpose                          |
|----------------------|----------------------------------|----------------------------------|
| VPC                  | AWS VPC                          | Network isolation                |
| Public Subnets       | AWS VPC                          | ALB, NAT Gateway                 |
| Private Subnets      | AWS VPC                          | EC2 instances, Redis             |
| Internet Gateway     | AWS VPC                          | Public internet access           |
| NAT Gateway          | AWS VPC                          | Outbound traffic for private subnets|
| Application Load Balancer | AWS ALB                     | Traffic distribution             |
| Auto Scaling Group   | AWS EC2 Auto Scaling             | Backend instance management      |
| Launch Template      | AWS EC2                          | EC2 instance configuration       |
| ECR Repository       | AWS ECR                          | Docker image storage             |
| S3 Bucket            | AWS S3                           | Frontend static hosting          |
| CloudFront Distribution | AWS CloudFront                | Content delivery network         |
| ElastiCache Cluster  | AWS ElastiCache (Redis)          | Session/cache management         |
| CloudWatch Dashboard | AWS CloudWatch                   | Application monitoring           |
| CloudWatch Alarms    | AWS CloudWatch                   | Alerting on issues               |
| SNS Topic            | AWS SNS                          | Email notifications              |
| IAM Roles/Policies   | AWS IAM                          | Security and permissions         |
| Security Groups      | AWS EC2                          | Network access control           |

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with admin credentials
- MongoDB Atlas account
- Domain name (optional, for HTTPS)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/Tbraima44/starttech-infra.git
   cd starttech-infra
```

1. Create the Terraform state backend
   ```bash
   # Create S3 bucket for state
   aws s3 mb s3://starttech-terraform-state-$(aws sts get-caller-identity --query Account --output text)
   
   # Create DynamoDB table for state locking
   aws dynamodb create-table \
     --table-name terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```
2. Configure variables
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform.tfvars with your values
   ```
3. Deploy infrastructure
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```
4. Get outputs
   ```bash
   terraform output
   ```

📁 Project Structure

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

🔒 Variables

Required Variables

Variable Description Example
key_name EC2 SSH key pair name "starttech-key"
mongodb_uri MongoDB Atlas connection string "mongodb+srv://user:pass@cluster.mongodb.net"
alarm_email Email for CloudWatch alarms "devops@example.com"

Optional Variables

Variable Default Description
project_name "starttech" Project name
environment "production" Deployment environment
aws_region "us-east-1" AWS region
instance_type "t3.medium" EC2 instance type
asg_min_size 2 Minimum ASG instances
asg_max_size 10 Maximum ASG instances
redis_node_type "cache.t3.micro" ElastiCache node type

📊 Outputs

Output Description
s3_bucket_name Frontend S3 bucket name
cloudfront_domain_name CloudFront distribution domain
cloudfront_distribution_id CloudFront distribution ID
ecr_repository_url ECR repository URL
asg_name Auto Scaling Group name
alb_dns_name Application Load Balancer DNS
redis_endpoint ElastiCache Redis endpoint

🚀 CI/CD Pipeline

The infrastructure uses GitHub Actions for automated deployment:

1. Plan: On pull request to main
2. Apply: On push to main
3. Destroy: Manual trigger only

Required GitHub Secrets

Secret Description
AWS_ACCESS_KEY_ID AWS access key
AWS_SECRET_ACCESS_KEY AWS secret key
MONGODB_URI MongoDB Atlas connection string
SSH_KEY_NAME EC2 SSH key pair name

📊 Monitoring

The infrastructure sets up:

· CloudWatch Dashboard: CPU, memory, request metrics
· CloudWatch Alarms: High CPU, unhealthy hosts, errors
· SNS Notifications: Email alerts for alarms
· CloudWatch Logs: Application and system logs

🔧 Maintenance

Scaling

```bash
# Update ASG capacity
terraform apply -var="asg_desired_capacity=5"
```

Updating Backend

```bash
# Deploy new backend version
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name starttech-asg-production
```

Destroying Infrastructure

```bash
# Warning: This removes ALL resources
./scripts/destroy-infrastructure.sh
```

🔒 Security

· All resources in private subnets (except ALB)
· Security groups restrict traffic between components
· IAM roles follow least privilege principle
· Encryption at rest and in transit
· Automated security scanning in CI/CD

🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Run terraform validate
5. Create a Pull Request

📄 License

MIT License - see LICENSE file

🙏 Acknowledgments

· AWS
· HashiCorp Terraform
· AltSchool Africa