aws_region   = "ap-northeast-1"
project_name = "image-analysis-api"
environment  = "dev"

# JP regional inference profile ID（Amazon Bedrock, Claude Haiku 4.5）
bedrock_inference_profile_id = "jp.anthropic.claude-haiku-4-5-20251001-v1:0"

# Actual foundation models that JP CRIS routes to (Tokyo/Osaka). Format does not include account_id.
bedrock_foundation_model_arns = [
  "arn:aws:bedrock:ap-northeast-1::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
  "arn:aws:bedrock:ap-northeast-3::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
]

# Finalized as a globally unique name
image_bucket_name     = "image-analysis-api-images-79cb9012"
image_expiration_days = 7

lambda_timeout     = 30
lambda_memory_size = 512
lambda_environment_variables = {
  LOG_LEVEL = "INFO"
}

tfstate_bucket_name = "image-analysis-api-tfstate-f28ff5c3"