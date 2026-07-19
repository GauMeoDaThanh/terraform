#modules/ec2-instance/_outputs.tf
output "ec2_instance_id" {
  value       = aws_instance.ec2_instance.id
  description = "ID of the instance"
}

output "private_ip" {
  value       = aws_instance.ec2_instance.private_ip
  description = "Private IP address of the instance"
}
