########################################
# modules/s3
#
# Bucket for storing uploaded item photos.
# Must be private, encrypted, and have public access blocked.
########################################

resource "aws_s3_bucket" "images" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket                  = aws_s3_bucket.images.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS configuration to support direct uploads via presigned URL from clients
resource "aws_s3_bucket_cors_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  cors_rule {
    allowed_methods = ["PUT"]
    allowed_origins  = var.cors_allowed_origins
    allowed_headers  = ["*"]
    max_age_seconds  = 3000
  }
}

# These are temporary working files, so auto-delete them after a set period (cost optimization)
resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "expire-old-uploads"
    status = "Enabled"

    filter {}

    expiration {
      days = var.expiration_days
    }
  }
}