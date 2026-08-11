variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "bedrock_inference_profile_arns" {
  description = "ARNs of the Bedrock inference profiles allowed to be invoked (e.g. jp.anthropic.claude-haiku-4-5-...)"
  type        = list(string)
}

variable "bedrock_foundation_model_arns" {
  description = "ARNs of the actual foundation models that JP CRIS routes to (both ap-northeast-1 and ap-northeast-3)"
  type        = list(string)
}

variable "image_bucket_arn" {
  description = "ARN of the S3 bucket storing uploaded images"
  type        = string
}