# StartTech Infrastructure Architecture

## Overview

The StartTech platform is deployed on AWS and consists of a frontend hosted on S3 and CloudFront, a backend API running on EC2 behind an Application Load Balancer, Redis for caching, and MongoDB Atlas as the database.

## Architecture Diagram

```

┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                           │
│  Region: us-east-1                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                     VPC (10.0.0.0/16)                 │  │
│  │                                                       │  │
│  │  ┌─────────────────┐  ┌──────────────────────────┐    │  │
│  │  │  Public Subnets │  │    Private Subnets       │    │  │
│  │  │                 │  │                          │    │  │
│  │  │  ┌────────────┐ │  │  ┌────────────────────┐  │    │  │
│  │  │  │    ALB     │ │  │  │   EC2 Auto Scaling │  │    │  │
│  │  │  │(HTTP/HTTPS)│ │  │  │       Group        │  │    │  │
│  │  │  └─────┬──────┘ │  │  └────────┬────────── ┘  │    │  │
│  │  │        │        │  │           │              │    │  │
│  │  └────────┼────────┘  └───────────┼ ─────────────┘    │  │
│  │           │                       │                   │  │
│  │  ┌────────┼───────────────────────│──────────────┐    │  │
│  │  │        │        NAT Gateway    │              │    │  │
│  │  └────────┼───────────────────────┼──────────────┘    │  │
│  │           │                       │                   │  │
│  │  ┌────────▼────────┐  ┌───────────▼───────────┐       │  │
│  │  │ Internet Gateway│  │  ElastiCache Redis    │       │  │
│  │  └─────────────────┘  └───────────────────────┘       │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │               External Services                       │  │
│  │  ┌─────────────────┐  ┌──────────────────────────┐    │  │
│  │  │  S3 + CloudFront│  │     MongoDB Atlas        │    │  │
│  │  │   (Frontend)    │  │     (Database)           │    │  │
│  │  └─────────────────┘  └──────────────────────────┘    │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

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
