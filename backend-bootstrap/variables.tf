variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "tfstate_bucket_name" {
  description = "S3 bucket name for tfstate"
  type        = string
}

variable "tflock_table_name" {
  description = "DynamoDB table name for tfstate locking"
  type        = string
  default     = "image-analysis-api-tflock"
}