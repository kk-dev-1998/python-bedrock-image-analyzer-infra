terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  bedrock_inference_profile_arns = [
    "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.bedrock_inference_profile_id}"
  ]
}

module "s3_images" {
  source = "../../modules/s3"

  bucket_name     = var.image_bucket_name
  expiration_days = var.image_expiration_days
}

module "iam" {
  source = "../../modules/iam"

  project_name                   = var.project_name
  environment                    = var.environment
  aws_region                     = var.aws_region
  account_id                     = data.aws_caller_identity.current.account_id
  bedrock_inference_profile_arns = local.bedrock_inference_profile_arns
  bedrock_foundation_model_arns  = var.bedrock_foundation_model_arns
  image_bucket_arn               = module.s3_images.bucket_arn
}

module "lambda" {
  source = "../../modules/lambda"

  project_name    = var.project_name
  environment     = var.environment
  lambda_role_arn = module.iam.lambda_role_arn
  image_uri       = var.image_uri
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment_variables = merge(
    var.lambda_environment_variables,
    {
      IMAGE_BUCKET_NAME    = module.s3_images.bucket_name
      BEDROCK_INFERENCE_ID = local.bedrock_inference_profile_arns[0]
    }
  )
}

module "apigateway" {
  source = "../../modules/apigateway"

  project_name         = var.project_name
  environment          = var.environment
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
}