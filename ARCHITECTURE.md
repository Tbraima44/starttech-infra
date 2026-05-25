```markdown
# StartTech Infrastructure Architecture

This document describes the AWS infrastructure provisioned by Terraform for the StartTech application. It covers networking, compute, storage, caching, database, monitoring, and security.

## High‑Level Diagram

```
      ┌──────────────────────────────────────────┐
      │              Internet Users              │
      └──────────────┬───────────────────────────┘
                     │ HTTPS
                     ▼
      ┌──────────────────────────────┐
      │        CloudFront CDN        │
      │   (Serves Frontend & Proxies │
      │         API Requests)        │
      └──────┬──────────────┬────────┘
             │              │
Static Assets│              │ API Requests
(/index.html,│              │ (/auth/*, /api/*,
 /assets/*)  │              │  /users/*, /tasks/*)
             ▼              ▼
      ┌──────────────┐  ┌─────────────────────────────┐
      │   S3 Bucket  │  │ Application Load Balancer   │
      │  (Frontend   │  │       (ALB - HTTP)          │
      │   Hosting)   │  │                             │
      └──────────────┘  └─────────────┬───────────────┘
                                      │ Forward to
                                      ▼
        ┌─────────────────────────────────────────────┐
        │          Auto Scaling Group (ASG)           │
        │       (Desired / Min / Max Instances)       │
        └───────────┬────────────────┬────────────────┘
                    │                │
    ┌───────────────┘                └───────────────┐
    │                                                │
    ▼                                                ▼
┌────────────────────────────────────────┐  ┌─────────────────────────────────────────┐
│         EC2 Instance (AZ-1)            │  │         EC2 Instance (AZ-2)             │
│         Private Subnet                 │  │         Private Subnet                  │
│                                        │  │                                         │     │                                        │  │                                         │
│  ┌───────────────────────────────────┐ │  │  ┌───────────────────────────────────┐  │
│  │   Docker Container (Backend)      │ │  │  │   Docker Container (Backend)      │  │
│  │   Port: 8080                      │ │  │  │   Port: 8080                      │  │
│  └────────┬──────────────┬───────────┘ │  │  └────────────┬────────┬─────────────┘  │
│           │              │             │  │               │        │                │
└───────────┼──────────────┼─────────────┘  └───────────────┼────────┼────────────────┘
            │              │                                │        │
            ▼              ▼                                │        │
┌──────────────┐  ┌───────────────────────┐                 │        │
│ MongoDB Atlas│  │ ElastiCache Redis     │◀───────────────┘        │
│   (External  │  │   (Cache / Sessions)  │                          │
│   Database)  │  │   Encrypted in Transit│◀────────────────────────┘
└──────────────┘  └───────────────────────┘
▲                            ▲
└──────────┬─────────────────┘
│
┌──────────┴───────────┐
│   CloudWatch         │
│   • Dashboard        │
│   • Log Groups       │
│   • Metrics (ALB,EC2)│
│   • Alarms (CPU,Host)│
│   • Logs Insights    │
└──────────────────────┘

```

## Network Architecture

- **VPC** with a CIDR block of `10.0.0.0/16` across two Availability Zones.
- **Public Subnets** host the Application Load Balancer and NAT Gateway.
- **Private Subnets** host the EC2 instances (backend) for security – they are not directly accessible from the internet.
- **Internet Gateway** allows outbound internet access for public subnets.
- **NAT Gateway** (in a public subnet) enables EC2 instances in private subnets to pull Docker images from ECR and connect to MongoDB Atlas.

### Security Groups
| Security Group | Purpose | Inbound Rules |
|---------------|---------|---------------|
| **ALB** | Allows HTTP (80) traffic from anywhere. | 0.0.0.0/0 on port 80 |
| **Backend** | Allows traffic only from the ALB on port 8080. | ALB security group on port 8080 |
| **Redis** | Allows traffic only from the backend security group on port 6379. | Backend security group on port 6379 |

## Compute

- **Auto Scaling Group (ASG)** manages a fleet of EC2 instances (desired: 2, min: 1, max: 3).
- **Launch Template** defines the instance configuration:
  - Amazon Linux 2 AMI
  - `t3.micro` instance type (Free Tier eligible)
  - User‑data script that installs Docker, pulls the backend image from ECR, and starts the container
  - IAM instance profile with permissions for CloudWatch logs and ECR access
- Instances are distributed across two Availability Zones for high availability.
- The ASG performs **rolling updates** (instance refresh) when the launch template changes, ensuring zero‑downtime deployments.

## Load Balancing

- **Application Load Balancer (ALB)** distributes incoming API requests to healthy backend instances.
- **Target Group** checks the health of each instance via the `/ping` endpoint on port 8080.
- The ALB listens on port 80 (HTTP). HTTPS can be enabled by attaching an ACM certificate and adding a listener on port 443.
- CloudFront proxies API requests (`/auth/*`, `/api/*`, `/users/*`, `/tasks/*`) to the ALB, keeping all traffic over HTTPS from the user's perspective.

## Storage & CDN

- **S3 Bucket** stores the built React frontend. It is configured for static website hosting and has a public read policy.
- **CloudFront Distribution** serves the frontend globally with low latency.
  - The default origin is the S3 bucket for static assets.
  - Additional origins and behaviors route API requests to the ALB.
  - Custom error responses (404 → `/index.html` with 200 status) support SPA routing.
- Cache invalidation is performed after each frontend deployment to ensure users receive the latest content.

## Caching

- **ElastiCache Redis** replication group provides in‑memory caching for the backend.
- The cluster runs in private subnets with encryption in transit and at rest.
- The backend connects to the primary endpoint and uses Redis for caching username availability checks and session data (when enabled).

## Database

- **MongoDB Atlas** is used as the external NoSQL database. It stores two collections: `users` and `todos`.
- The connection string is injected into the backend container via the `MONGO_URI` environment variable.
- Network access to Atlas must be configured to allow connections from the NAT Gateway's Elastic IP (or from `0.0.0.0/0` for development).

## Monitoring & Observability

- **CloudWatch Logs**: The CloudWatch agent is installed on each EC2 instance via user‑data. It collects application logs from `/var/log/application/*.log` and sends them to the log group `/aws/ec2/starttech-backend-production`.
- **CloudWatch Metrics**: Standard EC2, ALB, and ElastiCache metrics are collected automatically.
- **CloudWatch Dashboard**: A custom dashboard (`starttech-production`) displays key metrics (CPU utilization, ALB request count) and includes a Logs Insights widget that automatically runs a query to show the top 10 errors in the last hour.
- **CloudWatch Alarms**:
  - **High CPU Alarm**: Triggers if average CPU exceeds 80% for 2 evaluation periods. Sends an email notification.
  - **Unhealthy Host Alarm**: Triggers if any backend instance becomes unhealthy. Sends an email notification.
- **SNS Topic**: Alarms are published to an SNS topic that sends email notifications to the configured address.

## Security

- **IAM Roles and Policies**: The EC2 instance role (`starttech-ec2-role-production`) grants permissions to write logs to CloudWatch and pull images from ECR. The deployment policy grants GitHub Actions the minimum permissions needed to deploy.
- **Secrets Management**: Sensitive values (MongoDB URI, JWT secret, AWS credentials) are never stored in code. They are passed as Terraform variables (marked `sensitive`) or stored in GitHub Secrets.
- **Docker Security**: The backend Docker image runs as a non‑root user (`appuser`). Images are scanned for vulnerabilities during the CI/CD pipeline.
- **Network Security**: Security groups follow the least‑privilege principle. Backend instances are in private subnets and are not directly accessible from the internet.
- **Encryption**: Redis connections are encrypted in transit. Data is encrypted at rest in S3, ECR, and ElastiCache.

## Modules Overview

The Terraform configuration is organized into reusable modules:

| Module | Resources |
|--------|-----------|
| `networking` | VPC, subnets, Internet Gateway, NAT Gateway, route tables, security groups |
| `compute` | Launch template, Auto Scaling Group, ECR repository, IAM role and instance profile |
| `storage` | S3 bucket (with static website hosting and public policy), CloudFront distribution |
| `load_balancer` | ALB, target group, listeners |
| `cache` | ElastiCache subnet group and Redis replication group |
| `monitoring` | CloudWatch dashboard, metric alarms, SNS topic and email subscription |

## Deployment Workflow

1. **Terraform Plan**: Validates the configuration and shows planned changes.
2. **Terraform Apply**: Creates/updates all resources. The launch template is updated with a new version.
3. **Instance Refresh**: The ASG replaces running instances with new ones that use the updated launch template. This is triggered automatically by the CI/CD pipeline after a new Docker image is pushed to ECR.
```