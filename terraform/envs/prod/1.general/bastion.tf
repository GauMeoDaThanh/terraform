module "iam_role_ec2_bastion" {
  source = "../../../modules/iam-role"

  env     = var.env
  project = var.project

  name    = "ec2-bastion"
  service = "ec2"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  iam_default_policy_arn = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  iam_custom_policy = {
    template = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DescribeInstances",
            "ec2:DescribeTags",
            "ec2:DescribeAddresses",
            "ec2:CreateTags"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "AllowExecECS",
          "Effect" : "Allow",
          "Action" : [
            "ecs:ExecuteCommand",
            "ecs:DescribeTasks",
            "ecs:ListTasks"
          ],
          "Resource" : [
            "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.project}-${var.env}-api-ecs-cluster",
            "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${var.project}-${var.env}-api-ecs-cluster/${var.project}-${var.env}-*",
            "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task/${var.project}-${var.env}-api-ecs-cluster/*"
          ]
        }
      ]
    })
  }
  iam_instance_profile = true
}

module "security_group_ec2_bastion" {
  source = "../../../modules/security-group"

  env     = var.env
  project = var.project

  name          = "ec2-bastion"
  vpc_id        = module.vpc.vpc_id
  ingress_rules = []
}

module "ec2_instance_bastion" {
  source = "../../../modules/ec2-instance"

  env     = var.env
  project = var.project

  name                 = "bastion"
  ami_id               = data.aws_ami.ubuntu_24_04_arm64.id
  instance_type        = "t4g.micro"
  key_name             = "${var.project}-${var.env}-keypair"
  security_group_ids   = [module.security_group_ec2_bastion.security_group_id]
  subnet_id            = module.vpc.subnet_public_id[0]
  iam_instance_profile = module.iam_role_ec2_bastion.iam_instance_profile_id
  root_block_device = {
    volume_type = "gp3"
    volume_size = "20"
  }
  monitoring = false
  user_data  = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y postgresql-client

    # Install CloudWatch Agent
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb
    dpkg -i -E ./amazon-cloudwatch-agent.deb

    cat <<'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
      "agent": {
        "metrics_collection_interval": 300,
        "run_as_user": "root"
      },
      "metrics": {
        "append_dimensions": {
          "InstanceId": "$${aws:InstanceId}"
        },
        "metrics_collected": {
          "mem": {
            "measurement": [
              {"name": "mem_used_percent", "rename": "MemoryUtilization", "unit": "Percent"}
            ],
            "metrics_collection_interval": 300
          },
          "disk": {
            "measurement": [
              {"name": "used_percent", "rename": "DiskSpaceUtilization", "unit": "Percent"}
            ],
            "metrics_collection_interval": 300,
            "resources": ["/"]
          }
        }
      }
    }
    EOF

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  EOT
}
