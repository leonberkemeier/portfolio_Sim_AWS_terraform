# Variables allow us to parameterize our Terraform code so we can easily change environments (e.g., dev, prod)
variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project, used for resource tagging"
  type        = string
  default     = "financial-pipeline"
}

variable "db_password" {
  description = "The password for the Postgres RDS instance"
  type        = string
  sensitive   = true
  # In production, pass this via CLI or a .tfvars file, do not hardcode!
  default     = "SuperSecretPassword123!"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
