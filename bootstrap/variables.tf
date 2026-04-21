variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project   = "project-devops"
    ManagedBy = "Terraform"
    Purpose   = "DevOps Training"
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "project-devops"
}