# System Architecture

## Overview
Full-stack application with React frontend and Go backend.

## Components
- **Frontend**: React SPA on S3 + CloudFront
- **Backend**: Go API on EC2 with ALB
- **Cache**: ElastiCache Redis
- **Database**: MongoDB Atlas

## Network Flow
Internet → CloudFront → S3 (Frontend)
Internet → ALB → EC2 → Backend API → Redis/MongoDB
