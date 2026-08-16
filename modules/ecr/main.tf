########################################
# modules/ecr
#
# ECR repository for storing the Lambda container image.
# Like backend-bootstrap, Lambda (modules/lambda) depends on this
# repository's image URI, so it must be applied before other resources
# (apply it first with terraform apply -target=module.ecr).
########################################

resource "aws_ecr_repository" "app" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE" # Allow simple latest-tag usage for portfolio purposes

  image_scanning_configuration {
    scan_on_push = true # Automatically scan pushed images for vulnerabilities
  }
}

# Lifecycle policy to cap the number of retained images,
# preventing unbounded image accumulation and rising costs
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last N images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}