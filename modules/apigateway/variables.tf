variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_invoke_arn" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "throttling_rate_limit" {
  type    = number
  default = 2
}

variable "throttling_burst_limit" {
  type    = number
  default = 5
}