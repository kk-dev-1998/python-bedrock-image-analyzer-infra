variable "github_org" {
  description = "GitHub username/organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "tfstate_bucket_name" {
  description = "S3 bucket name for tfstate"
  type        = string
}