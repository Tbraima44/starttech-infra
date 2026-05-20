#!/bin/bash
set -e
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
yum install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWEOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/application/*.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
CWEOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${ecr_repository}
docker pull ${ecr_repository}:${image_tag}
docker stop backend || true
docker rm backend || true

# Start the container with environment variables – ONE continuous line using backslashes
docker run -d --name backend --restart always -p 8080:8080 \
  -e PORT=8080 \
  -e MONGO_URI="${mongodb_uri}" \
  -e DB_NAME=todos \
  -e JWT_SECRET_KEY=production-secret \
  -e JWT_EXPIRATION_HOURS=72 \
  -e ENABLE_CACHE=false \
  -e REDIS_ADDR="${redis_endpoint}:6379" \
  -e REDIS_PASSWORD= \
  -e LOG_LEVEL=debug \
  -e LOG_FORMAT=text \
  -v /var/log/application:/var/log/application \
  ${ecr_repository}:${image_tag}