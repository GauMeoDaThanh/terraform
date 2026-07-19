# Need to create a keypair on AWS console first
resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_type           = var.root_block_device.volume_type
    volume_size           = var.root_block_device.volume_size
    delete_on_termination = true
  }

  credit_specification {
    cpu_credits = var.cpu_credits
  }

  disable_api_termination = var.disable_api_termination
  monitoring              = var.monitoring
  user_data               = var.user_data

  tags = {
    Name = "${var.project}-${var.env}-${var.name}-ec2-instance"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [ami]
  }
}
