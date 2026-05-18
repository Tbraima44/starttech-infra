output "vpc_id" {
  value = module.networking.vpc_id
}

output "alb_dns_name" {
  value = module.load_balancer.alb_dns_name
}

output "cloudfront_domain_name" {
  value = module.storage.cloudfront_domain_name
}

output "s3_bucket_name" {
  value = module.storage.s3_bucket_name
}

output "ecr_repository_url" {
  value = module.compute.ecr_repository_url
}

output "redis_endpoint" {
  value = module.cache.redis_endpoint
}

output "frontend_url" {
  value = "https://${module.storage.cloudfront_domain_name}"
}

output "backend_url" {
  value = "http://${module.load_balancer.alb_dns_name}"
}

output "cloudfront_distribution_id" {
   value = module.storage.cloudfront_distribution_id 
}
