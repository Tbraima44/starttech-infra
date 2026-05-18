#!/bin/bash
set -e

echo "WARNING: This will destroy all infrastructure resources."
read -p "Are you sure? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

cd terraform
terraform destroy -auto-approve

echo "Infrastructure destroyed."
