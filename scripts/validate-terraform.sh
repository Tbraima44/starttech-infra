#!/bin/bash
set -e

echo "Validating Terraform configuration..."

cd terraform

# Format check
echo "Checking formatting..."
terraform fmt -check -recursive

# Initialize
echo "Initializing..."
terraform init -backend=false

# Validate
echo "Validating..."
terraform validate

echo "Validation complete!"
