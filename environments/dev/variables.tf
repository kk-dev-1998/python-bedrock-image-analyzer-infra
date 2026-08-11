variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "project_name" {
  type    = string
  default = "image-analysis-api"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "bedrock_inference_profile_id" {
  description = "JP regional inference profile ID"
  type        = string
}

variable "bedrock_foundation_model_arns" {
  description = "ARNs of the actual foundation models that JP CRIS routes to (ap-northeast-1 / ap-northeast-3)"
  type        = list(string)
}

variable "image_bucket_name" {
  description = "S3 bucket name for image uploads"
  type        = string
}

variable "image_expiration_days" {
  type    = number
  default = 7
}

variable "image_uri" {
  description = "Lambda container image URI on ECR"
  type        = string
}

variable "lambda_timeout" {
  type    = number
  default = 30
}

variable "lambda_memory_size" {
  type    = number
  default = 512
}

variable "lambda_environment_variables" {
  type    = map(string)
  default = {}
}