output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.openclaw.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.openclaw.public_ip
}

output "schedule_start" {
  description = "Instance start schedule"
  value       = "Daily at 6:00 AM America/Bogota"
}

output "schedule_stop" {
  description = "Instance stop schedule"
  value       = "Daily at 6:00 PM America/Bogota"
}
