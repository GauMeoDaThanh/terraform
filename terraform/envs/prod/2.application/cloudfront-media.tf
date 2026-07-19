module "cloudfront_media" {
  source = "../../../modules/cloudfront"

  env     = var.env
  project = var.project

  cloudfront_name           = "media"
  cloudfront_price_class    = "PriceClass_200"
  cloudfront_aliases_domain = ["media.${var.domain_name}"]

  cloudfront_viewer_certificate = {
    cloudfront_default_certificate = false
    acm_certificate_arn            = data.terraform_remote_state.general.outputs.acm_cloudfront_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  cloudfront_origins = [
    {
      s3_origin_config = true
      domain_name      = module.s3_media.s3_bucket_regional_domain_name
      origin_id        = "s3-media"
    }
  ]

  cloudfront_default_cache_behavior = {
    target_origin_id       = "s3-media"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
  }
}

##################
# Route53 Media
##################
module "route53_record_media" {
  source = "../../../modules/route53"

  env     = var.env
  project = var.project

  route53_zone_id = data.aws_route53_zone.selected.id
  route53_alias_records = [
    {
      name = "media.${var.domain_name}"
      alias = {
        dns_name = module.cloudfront_media.cloudfront_domain_name
        zone_id  = module.cloudfront_media.cloudfront_hosted_zone_id
      }
    }
  ]
}
