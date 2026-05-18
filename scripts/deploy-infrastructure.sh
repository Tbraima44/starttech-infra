#!/bin/bash
set -e

echo "Deploying StartTech Infrastructure..."

# Initialize Terraform
cd terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Apply deployment
terraform apply tfplan

echo "Infrastructure deployment complete!"
