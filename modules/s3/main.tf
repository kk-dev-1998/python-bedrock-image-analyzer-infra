########################################
# modules/s3
#
# Bucket for storing uploaded item photos.
# Must be private, encrypted, and have public access blocked.
########################################

resource "aws_s3_bucket" "images" {
  # checkov:skip=CKV2_AWS_62:Curretnly notification is not requierd in the flow. Confidential data should no be uploaded.
  # checkov:skip=CKV_AWS_18,CKV_AWS_21,CKV_AWS_144,CKV_AWS_145:The data is temporary data and not confidential.

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
    allowed_origins = var.cors_allowed_origins
    allowed_headers = ["*"]
    max_age_seconds = 3000
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

    abort_incomplete_multipart_upload {
      days_after_initiation = 1 # Delete incomplete multipart uploads after 1 day
    }
  }
}