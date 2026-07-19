module "s3_media" {
  source = "../../../modules/s3"

  s3_bucket = {
    name       = "${var.project}-${var.env}-media"
    versioning = "Enabled"
    cors_rule = [
      {
        allowed_headers = ["*"]
        allowed_methods = ["GET", "HEAD", "PUT", "POST"]
        allowed_origins = ["https://app.${var.domain_name}"]
        expose_headers  = ["ETag"]
        max_age_seconds = 3600
      }
    ]
  }

  s3_bucket_policy = {
    template = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowCloudFrontServicePrincipal",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "cloudfront.amazonaws.com"
          },
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::${var.project}-${var.env}-media/*",
          "Condition" : {
            "StringEquals" : {
              "AWS:SourceArn" : module.cloudfront_media.cloudfront_arn
            }
          }
        }
      ]
    })
  }
}
