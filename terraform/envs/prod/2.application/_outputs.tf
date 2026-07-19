output "ecs_cluster_id" {
  value = module.ecs_api.ecs_cluster_id
}
output "alb_dns_name" {
  value = module.alb_api.alb_dns_name
}
output "aurora_cluster_endpoint" {
  value = module.aurora.cluster_endpoint
}
output "cloudfront_frontend_domain" {
  value = module.cloudfront_frontend.cloudfront_domain_name
}
output "cloudfront_media_domain" {
  value = module.cloudfront_media.cloudfront_domain_name
}
