variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "openclaw"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t4g.medium"
}

variable "key_name" {
  description = "SSH key pair name for EC2 access. Leave empty to disable SSH key."
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance. Leave empty to use latest Amazon Linux 2023 ARM64."
  type        = string
  default     = ""
}
