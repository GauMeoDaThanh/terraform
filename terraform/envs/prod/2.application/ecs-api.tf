###################################
# Cloudwatch Log Group API
###################################
resource "aws_cloudwatch_log_group" "ecs_api" {
  name              = "${var.project}-${var.env}-ecs-api"
  retention_in_days = 30
}

#############################
# Security Group ECS API
#############################
module "security_group_ecs_api" {
  source = "../../../modules/security-group"

  env     = var.env
  project = var.project

  name   = "ecs-api"
  vpc_id = data.terraform_remote_state.general.outputs.vpc_id
  ingress_rules = [
    {
      from_port       = 3000
      to_port         = 3000
      protocol        = "tcp"
      security_groups = [module.security_group_alb_api.security_group_id]
      description     = "Allow ALB access ECS API"
    }
  ]
}

##################
# ECS API
##################
module "ecs_api" {
  source = "../../../modules/ecs"

  env     = var.env
  project = var.project

  ecs_cluster_name = "api"

  ecs_task_definitions = {
    execution_role_arn = module.iam_role_ecs_task_execution_api.iam_role_arn
    task_definitions = [
      {
        name          = "api"
        total_memory  = 1024
        total_cpu     = 512
        task_role_arn = module.iam_role_ecs_task_api.iam_role_arn
        container_definitions = {
          template = "${path.module}/templates/api-task-definition.json"
          vars = {
            name           = "api"
            image          = "${module.ecr_api.ecr_repository_url}:latest"
            container_port = 3000
            host_port      = 3000
            awslogs_group  = aws_cloudwatch_log_group.ecs_api.name
            awslogs_region = var.region
          }
        }
      }
    ]
  }

  ecs_services = [
    {
      name                  = "api"
      task_definition_arn   = module.ecs_api.ecs_task_definition_arn["api"]
      desired_count         = 2
      security_group_ids    = [module.security_group_ecs_api.security_group_id]
      subnet_ids            = data.terraform_remote_state.general.outputs.subnet_app_id
      deployment_controller = "ECS"
      load_balancer = {
        target_group_arn = module.alb_api.alb_target_group_arn["api"]
        container_name   = "api"
        container_port   = 3000
      }
    }
  ]
}
