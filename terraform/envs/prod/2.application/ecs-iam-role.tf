###################
#ECS Task role API
###################
module "iam_role_ecs_task_api" {
  source = "../../../modules/iam-role"

  env     = var.env
  project = var.project

  name    = "ecs-task-api"
  service = "ecs"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
          Action = "sts:AssumeRole"
        }
      ]
    }
  )
  iam_custom_policy = {
    template = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "SSMMessages",
            "Effect" : "Allow",
            "Action" : [
              "ssmmessages:CreateControlChannel",
              "ssmmessages:CreateDataChannel",
              "ssmmessages:OpenControlChannel",
              "ssmmessages:OpenDataChannel"
            ],
            "Resource" : "*"
          },
          {
            "Sid" : "S3MediaBucket",
            "Effect" : "Allow",
            "Action" : [
              "s3:PutObject",
              "s3:GetObject",
              "s3:ListBucket",
              "s3:DeleteObject"
            ],
            "Resource" : [
              module.s3_media.s3_bucket_arn,
              "${module.s3_media.s3_bucket_arn}/*"
            ]
          }
        ]
      }
    )
  }
}

###########################
#ECS Task execution role API
###########################
module "iam_role_ecs_task_execution_api" {
  source = "../../../modules/iam-role"

  env     = var.env
  project = var.project

  name    = "ecs-task-execution-api"
  service = "ecs"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
          Action = "sts:AssumeRole"
        }
      ]
    }
  )
  iam_custom_policy = {
    template = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "ECRAuthPolicy",
            "Effect" : "Allow",
            "Action" : [
              "ecr:GetAuthorizationToken"
            ],
            "Resource" : "*"
          },
          {
            "Sid" : "ECRRepositoryPermissions",
            "Effect" : "Allow",
            "Action" : [
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage"
            ],
            "Resource" : "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.project}-${var.env}-*"
          },
          {
            "Sid" : "CloudWatchLogsPolicy",
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "logs:DescribeLogStreams"
            ],
            "Resource" : "*"
          },
          {
            "Sid" : "SecretsManagerGetSecret",
            "Effect" : "Allow",
            "Action" : [
              "secretsmanager:GetSecretValue"
            ],
            "Resource" : "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:/prod/*"
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "kms:Decrypt"
            ],
            "Resource" : data.terraform_remote_state.general.outputs.kms_shared_arn
          }
        ]
      }
    )
  }
}
