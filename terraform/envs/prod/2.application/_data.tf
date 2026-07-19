data "terraform_remote_state" "general" {
  backend = "s3"
  config = {
    bucket = "poc-prod-iac-state"
    key    = "general/terraform.prod.tfstate"
    region = var.region
  }
}

data "aws_caller_identity" "current" {}

data "sops_file" "secret_enc" {
  source_file = "${path.module}/../../../../sops/secrets.prod.yaml"
}

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "ubuntu_22" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
