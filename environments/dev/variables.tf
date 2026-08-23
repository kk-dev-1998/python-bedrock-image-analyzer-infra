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

variable "ecr_max_image_count" {
  description = "Maximum number of images to keep in ECR"
  type        = number
  default     = 5
}

variable "image_tag" {
  description = "ECR image tag"
  type        = string
  default     = "latest"
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

variable "tfstate_bucket_name" {
  description = "S3 bucket name for storing Terraform state"
  type        = string
}