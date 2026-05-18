#!/bin/bash
set -e
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
yum install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
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
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${ecr_repository}
docker pull ${ecr_repository}:${image_tag}
docker stop backend || true
docker rm backend || true
docker run -d --name backend --restart always -p 8080:8080 \
  -e ENVIRONMENT=${environment} \
  -e REDIS_ENDPOINT=${redis_endpoint} \
  -e MONGODB_URI=${mongodb_uri} \
  -v /var/log/application:/var/log/application \
  ${ecr_repository}:${image_tag}