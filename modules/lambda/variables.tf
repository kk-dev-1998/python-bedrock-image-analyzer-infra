variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_role_arn" {
  type = string
}

variable "image_uri" {
  description = "Container image URI on ECR (e.g. <account_id>.dkr.ecr.<region>.amazonaws.com/image-analysis-api:latest)"
  type        = string
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memory_size" {
  type    = number
  default = 512
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "reserved_concurrent_executions" {
  type    = number
  default = 5
}