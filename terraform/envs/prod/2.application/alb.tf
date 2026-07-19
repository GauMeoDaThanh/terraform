#############################
# Security Group ALB API
#############################
module "security_group_alb_api" {
  source = "../../../modules/security-group"

  env     = var.env
  project = var.project

  name   = "alb-api"
  vpc_id = data.terraform_remote_state.general.outputs.vpc_id
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all IPs to HTTP ALB"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all IPs to HTTPS ALB"
    }
  ]
}

##################
# ALB API
##################
module "alb_api" {
  source = "../../../modules/alb"

  env     = var.env
  project = var.project

  type = "api"
  alb = {
    security_groups_id = [module.security_group_alb_api.security_group_id]
    subnets_id         = data.terraform_remote_state.general.outputs.subnet_public_id
    logs_bucket_id     = data.terraform_remote_state.general.outputs.s3_logs_id
    idle_timeout       = 120
  }

  alb_target_group = {
    vpc_id = data.terraform_remote_state.general.outputs.vpc_id
    target_groups = [
      {
        name                 = "api"
        target_type          = "ip"
        port                 = 3000
        deregistration_delay = 60
        health_check = {
          port                = 3000
          path                = "/api/v1/health"
          unhealthy_threshold = 3
          interval            = 30
          timeout             = 20
        }
      }
    ]
  }

  alb_listeners = [
    {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type     = "redirect"
        redirect = { port = 443 }
      }
    },
    {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
      certificate_arn = data.terraform_remote_state.general.outputs.acm_arn
      default_action = {
        type    = "forward"
        forward = { target_group_arn = module.alb_api.alb_target_group_arn["api"] }
      }
    }
  ]

  alb_listener_rules = []
}

##################
# Route53 API
##################
module "route53_record_api" {
  source = "../../../modules/route53"

  env     = var.env
  project = var.project

  route53_zone_id = data.aws_route53_zone.selected.id
  route53_alias_records = [
    {
      name = "api.${var.domain_name}"
      alias = {
        dns_name = module.alb_api.alb_dns_name
        zone_id  = module.alb_api.alb_zone_id
      }
    }
  ]
}
