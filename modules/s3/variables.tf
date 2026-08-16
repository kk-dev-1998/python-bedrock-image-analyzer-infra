variable "bucket_name" {
  description = "Bucket name for image storage "
  type        = string
}

variable "expiration_days" {
  description = "Number of days before uploaded images are automatically deleted"
  type        = number
  default     = 7
}

variable "cors_allowed_origins" {
  description = "List of origins allowed to upload directly via presigned URL"
  type        = list(string)
  default     = ["*"]
}