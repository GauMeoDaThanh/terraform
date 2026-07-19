module "cloudfront_frontend" {
  source = "../../../modules/cloudfront"

  env     = var.env
  project = var.project

  cloudfront_name                = "frontend"
  cloudfront_price_class         = "PriceClass_200"
  cloudfront_default_root_object = "index.html"
  cloudfront_aliases_domain      = ["app.${var.domain_name}"]

  cloudfront_viewer_certificate = {
    cloudfront_default_certificate = false
    acm_certificate_arn            = data.terraform_remote_state.general.outputs.acm_cloudfront_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  cloudfront_origins = [
    {
      s3_origin_config = true
      domain_name      = module.s3_frontend.s3_bucket_regional_domain_name
      origin_id        = "s3-frontend"
    }
  ]

  cloudfront_default_cache_behavior = {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  cloudfront_custom_error_responses = [
    {
      error_code            = 403
      error_caching_min_ttl = 10
      response_page_path    = "/index.html"
      response_code         = 200
    },
    {
      error_code            = 404
      error_caching_min_ttl = 10
      response_page_path    = "/index.html"
      response_code         = 200
    }
  ]
}

##################
# Route53 Frontend
##################
module "route53_record_frontend" {
  source = "../../../modules/route53"

  env     = var.env
  project = var.project

  route53_zone_id = data.aws_route53_zone.selected.id
  route53_alias_records = [
    {
      name = "app.${var.domain_name}"
      alias = {
        dns_name = module.cloudfront_frontend.cloudfront_domain_name
        zone_id  = module.cloudfront_frontend.cloudfront_hosted_zone_id
      }
    }
  ]
}
