output "asg_name" { value = aws_autoscaling_group.backend.name }
output "ecr_repository_url" { value = aws_ecr_repository.backend.repository_url }