variable "repository_name" {
  description = "ECR repository name"
  type        = string
}

variable "max_image_count" {
  description = "Maximum number of images to keep (excess images will be automatically deleted)"
  type        = number
  default     = 5
}