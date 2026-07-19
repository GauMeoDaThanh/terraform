module "s3_frontend" {
  source = "../../../modules/s3"

  s3_bucket = {
    name       = "${var.project}-${var.env}-frontend"
    versioning = "Enabled"
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
          "Resource" : "arn:aws:s3:::${var.project}-${var.env}-frontend/*",
          "Condition" : {
            "StringEquals" : {
              "AWS:SourceArn" : module.cloudfront_frontend.cloudfront_arn
            }
          }
        }
      ]
    })
  }
}
