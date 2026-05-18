#!/bin/bash
set -e

echo "Setting up CloudWatch Dashboard..."

aws cloudwatch put-dashboard \
    --dashboard-name "StartTech-Dashboard" \
    --dashboard-body file://monitoring/cloudwatch-dashboard.json

echo "Dashboard setup complete!"
