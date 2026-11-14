# ==============================================================================
# Variables Configuration
# ==============================================================================

variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type (Technical requirement: t2.micro)"
  type        = string
  default     = "t2.micro"
}

variable "project_name" {
  description = "Name prefix for resource tagging and naming"
  type        = string
  default     = "nginx-deployment"
}

variable "key_name" {
  description = "Optional EC2 Key Pair name for SSH access"
  type        = string
  default     = ""
}
