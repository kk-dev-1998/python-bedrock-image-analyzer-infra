########################################
# modules/iam
#
# Creates the Lambda execution role with least-privilege permissions.
# - Write access to CloudWatch Logs (only its own log group)
# - InvokeModel access only for the specified Amazon Bedrock models
########################################

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project_name}-lambda-exec-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}:*",
      "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}",
    ]
  }

  # Permission to invoke the JP regional inference profile (jp.anthropic.claude-haiku-4-5-...).
  # CRIS requires two statements: one granting access to the inference profile itself,
  # and one granting access to the actual routed models (Tokyo/Osaka).
  statement {
    sid       = "BedrockInvokeInferenceProfile"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel*"]
    resources = var.bedrock_inference_profile_arns
  }

  statement {
    sid       = "BedrockInvokeRoutedFoundationModel"
    effect    = "Allow"
    actions   = ["bedrock:InvokeModel*"]
    resources = var.bedrock_foundation_model_arns

    condition {
      test     = "StringLike"
      variable = "bedrock:InferenceProfileArn"
      values   = var.bedrock_inference_profile_arns
    }
  }

  statement {
    sid    = "S3ImageReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${var.image_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name   = "${var.project_name}-lambda-policy-${var.environment}"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}