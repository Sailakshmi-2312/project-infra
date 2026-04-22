variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "repositories" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = [
    "frontend",
    "api-gateway",
    "product-service",
    "order-service",
    "cart-service",
    "user-service"
  ]
}

variable "image_tag_mutability" {
  description = "Image tag mutability (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "lifecycle_policy_count" {
  description = "Number of images to keep per repository"
  type        = number
  default     = 30
}