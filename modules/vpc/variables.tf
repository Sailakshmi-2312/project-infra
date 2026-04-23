variable "project_name" {
    description = "project name for resource naming"
    type = string
}

variable "environment" {
  description = "Environemnt type [dev/prod]"
  type = string
}

variable "vpc_cidr" {
    description = "CIDR block for vpc"
    type = string
    default = "10.0.0.0/16"
}

variable "azs" {
    description = "Availability zones"
    type = list(string)
    default = ["ap-south-1a","ap-south-1b"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type = list(string)
  default = [ "10.0.10.0/24","10.0.20.0/24" ]
}

variable "single_nat_gateway" {
  description = "Use single NAT gateway (cost optimization)"
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC endpoint"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "enable_ecr_endpoints" {
  description = "Enable ECR VPC endpoints"
  type        = bool
  default     = false  # ~$15/month - enable for prod
}

variable "enable_log_endpoints" {
  description = "Enable log VPC endpoints"
  type        = bool
  default     = false  # ~$15/month - enable for prod
}

variable "enable_sts_endpoints" {
  description = "Enable sts VPC endpoints"
  type        = bool
  default     = false  # ~$15/month - enable for prod
}
