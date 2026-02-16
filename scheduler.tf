# IAM Role for EventBridge Scheduler to manage EC2 instances
resource "aws_iam_role" "scheduler" {
  name = "${var.project_name}-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "scheduler_ec2" {
  name = "${var.project_name}-ec2-start-stop"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = aws_instance.openclaw.arn
      }
    ]
  })
}

# Schedule group
resource "aws_scheduler_schedule_group" "openclaw" {
  name = var.project_name
}

# Start instance at 6:00 AM Bogota (America/Bogota)
resource "aws_scheduler_schedule" "start_instance" {
  name       = "${var.project_name}-start"
  group_name = aws_scheduler_schedule_group.openclaw.name

  schedule_expression          = "cron(0 6 * * ? *)"
  schedule_expression_timezone = "America/Bogota"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      InstanceIds = [aws_instance.openclaw.id]
    })
  }
}

# Stop instance at 6:00 PM Bogota (America/Bogota)
resource "aws_scheduler_schedule" "stop_instance" {
  name       = "${var.project_name}-stop"
  group_name = aws_scheduler_schedule_group.openclaw.name

  schedule_expression          = "cron(0 18 * * ? *)"
  schedule_expression_timezone = "America/Bogota"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      InstanceIds = [aws_instance.openclaw.id]
    })
  }
}
