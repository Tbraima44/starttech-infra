resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnet-${var.environment}"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-redis-${var.environment}"
  description          = "Redis for ${var.project_name}"
  node_type            = var.node_type
  port                 = 6379
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [var.security_group_id]
  automatic_failover_enabled = var.num_cache_nodes > 1 ? true : false
  num_cache_clusters         = var.num_cache_nodes
  engine                    = "redis"
  engine_version            = "7.0"
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  tags = { Environment = var.environment }
}