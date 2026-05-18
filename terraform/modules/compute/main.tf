data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile { name = aws_iam_instance_profile.ec2_profile.name }
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment    = var.environment
    ecr_repository = aws_ecr_repository.backend.repository_url
    image_tag      = var.backend_image_tag
    region         = var.aws_region
    log_group_name = var.log_group_name
    redis_endpoint = var.redis_endpoint
    mongodb_uri    = var.mongodb_uri
  }))
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-backend-${var.environment}"
      Environment = var.environment
    }
  }
}

resource "aws_autoscaling_group" "backend" {
  name                = "${var.project_name}-asg-${var.environment}"
  vpc_zone_identifier = var.private_subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  target_group_arns   = [var.target_group_arn]
  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
  health_check_type         = "ELB"
  health_check_grace_period = 300
  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend-${var.environment}"
    propagate_at_launch = true
  }
}

resource "aws_ecr_repository" "backend" {
  name = "${var.project_name}-backend-${var.environment}"
  image_scanning_configuration { scan_on_push = true }
  tags = { Environment = var.environment }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "${var.project_name}-ec2-policy-${var.environment}"
  role = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:log-group:${var.log_group_name}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["cloudwatch:PutMetricData", "ec2:DescribeTags"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_role.name
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.backend.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.backend.name
}

# CloudWatch log group for backend logs (created here to pass name to monitoring module)
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/aws/ec2/${var.project_name}-backend-${var.environment}"
  retention_in_days = 30
  tags = { Environment = var.environment }
}