# StartTech Infrastructure Architecture

## Overview

The StartTech platform is deployed on AWS and consists of a frontend hosted on S3 and CloudFront, a backend API running on EC2 behind an Application Load Balancer, Redis for caching, and MongoDB Atlas as the database.

## Architecture Diagram

```mermaid
flowchart TB
    subgraph AWS[AWS Cloud - us-east-1]
        subgraph VPC[VPC 10.0.0.0/16]
            subgraph Public[Public Subnets]
                ALB[Application Load Balancer]
                IGW[Internet Gateway]
            end

            subgraph Private[Private Subnets]
                ASG[EC2 Auto Scaling Group]
                REDIS[ElastiCache Redis]
                NAT[NAT Gateway]
            end
        end

        subgraph External[External Services]
            CF[CloudFront]
            S3[S3 Static Hosting]
            MONGO[MongoDB Atlas]
        end
    end

    User[User]
    User -->|HTTPS| CF
    CF -->|Serves static assets| S3
    User -->|HTTPS| ALB
    ALB -->|Routes traffic| ASG
    ASG -->|Reads/Writes cache| REDIS
    ASG -->|Database access| MONGO
    ASG -->|Outbound internet access| NAT
    NAT -->|Egress| IGW
    IGW -->|Public internet| User

    classDef default fill:#0f172a,stroke:#38bdf8,color:#e2e8f0;
    classDef subgraph fill:#111827,stroke:#475569,color:#e2e8f0;
    class AWS subgraph
    class VPC subgraph
    class Public subgraph
    class Private subgraph
    class External subgraph
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
