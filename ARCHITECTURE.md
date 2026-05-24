# StartTech Infrastructure Architecture

## Overview

The StartTech platform is deployed on AWS and consists of a frontend hosted on S3 and CloudFront, a backend API running on EC2 behind an Application Load Balancer, Redis for caching, and MongoDB Atlas as the database.

## Architecture Diagram

```
graph TD
    subgraph "Users"
        User[🌐 Internet Users]
    end

    subgraph "AWS Cloud"
        subgraph "Global Services"
            CF[CloudFront CDN<br/>E3SZN3R2L7RW89]
            S3[S3 Bucket<br/>starttech-frontend-production-565897770092<br/>Static Website Hosting]
            ECR[ElastiCache Redis<br/>master.starttech-redis-production.xsbsfs.use1.cache.amazonaws.com]
            ATLAS[MongoDB Atlas<br/>External Service]
            CW[CloudWatch<br/>Logs, Metrics, Alarms, Dashboard]
        end

        subgraph "VPC - vpc-0e52fb1d922ccb8bc<br/>10.0.0.0/16"
            subgraph "Availability Zone 1"
                PUB1[Public Subnet]
                PRIV1[Private Subnet]
                EC2_1[EC2 Instance<br/>Backend (Docker)<br/>Health Checks]
            end
            subgraph "Availability Zone 2"
                PUB2[Public Subnet]
                PRIV2[Private Subnet]
                EC2_2[EC2 Instance<br/>Backend (Docker)<br/>Health Checks]
            end
            IGW[Internet Gateway]
            NAT[NAT Gateway]
            ALB[Application Load Balancer<br/>starttech-alb-production-2041761124.us-east-1.elb.amazonaws.com]
            ASG[Auto Scaling Group<br/>starttech-asg-production<br/>Desired: 2, Min: 1, Max: 10]
        end
    end

    User -->|HTTPS| CF
    CF -->|Static Assets| S3
    CF -->|/auth/*, /api/*, /users/*, /tasks/*| ALB
    ALB -->|Forward to| ASG
    ASG -->|Launches| EC2_1
    ASG -->|Launches| EC2_2
    EC2_1 -.->|Pulls Image| ECR
    EC2_2 -.->|Pulls Image| ECR
    EC2_1 -->|Connects to| ECR[(Redis)]
    EC2_2 -->|Connects to| ECR
    EC2_1 -->|Connects to| ATLAS[(MongoDB)]
    EC2_2 -->|Connects to| ATLAS
    EC2_1 & EC2_2 -.->|Logs & Metrics| CW
    CF & ALB & ECR & EC2 -.->|Metrics| CW
    IGW --> PUB1 & PUB2
    NAT --> PRIV1 & PRIV2
```

## Components

### Frontend

- React SPA hosted in S3
- Delivered through CloudFront for low-latency access

### Backend

- Go API deployed on EC2 instances
- Managed by an Auto Scaling Group
- Exposed through an Application Load Balancer

### Caching

- ElastiCache Redis used for session and cache data

### Database

- MongoDB Atlas provides the managed database backend

## Network Flow

1. Users access the application through CloudFront.
2. Static frontend assets are served from S3.
3. API requests are routed through the ALB to the backend EC2 instances.
4. Backend services connect to Redis and MongoDB Atlas for data access.

## Security and Availability

- VPC isolates the infrastructure into public and private subnets.
- Internet Gateway provides public access for the ALB and CloudFront entry points.
- NAT Gateway allows private instances to reach external services securely.
- Security groups and IAM roles limit access between components.

## Region

- Deployment region: `us-east-1`
